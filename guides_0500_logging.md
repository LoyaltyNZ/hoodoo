---
layout: default
categories: [guide]
title: Logging
---

## Purpose

Hoodoo provides support for both synchronous fast and asynchronous slow log sinks. Multiple log destinations can be configured. This Guide describes the 'raw' logging system and the way in which the service middleware and associated empty [service shell]({{ site.baseurl }}/guides_0100_fundamentals.html#Shell) drives it.

Underpinning all logging is the `Hoodoo::Logger` class. The [RDoc information for this]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Logger.html) covers the details extensively, so this Guide focuses on feature discovery and examples.

## Manual logging

### Choosing writers

Log output "writers" are subclasses of [`Hoodoo::Logger::FastWriter`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Logger/FastWriter.html) (synchronous, not threaded) or [`Hoodoo::Logger::SlowWriter`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Logger/SlowWriter.html) (asynchronous via Ruby threads). Hoodoo comes with writer classes including a [stream writer]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Logger/StreamWriter.html) which can be used for things like console output and a [LogEntries.com](https://logentries.com) [writer]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Logger/LogEntriesDotComWriter.html) that uses the `le` gem to send messages 'into the cloud' for deeper analysis.

Instantiate a `Hoodoo::Logger`, instantiate one or more writers, then add them:

```ruby
file_writer   = Hoodoo::Logger::FileWriter.new( 'output.log' )
stdout_writer = Hoodoo::Logger::StreamWriter.new

logger = Hoodoo::Logger.new

logger.add( file_writer   )
logger.add( stdout_writer )
```

### Log levels

The logger supports our log levels: `debug`, `info`, `warn` and `error`, listed in order of importance/severity from least to most. Every message sent to the logging system has an associated level chosen from this set. The logger instance is configured to filter out messages below a certain severity. The setting is inclusive; by default the level is `debug`, so everything including the `debug` level, or more severe than that, gets logged. Suppose we only wanted to see information, warnings and errors, but not the debug messages:

```ruby
logger.level = :info
```

### Sending messages

Once you have a logger instance configured with the required writer(s). Ideally, use the structured output method [`report`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Logger.html#method-i-report) for this:

```ruby
logger.report(
  :warn,
  'Example',
  'message',
  {
    :field_one => 'This is message field one',
    :field_two => 'This is message field two'
  }
)
```

The method takes a _level_, a _component_ and _code_ in addition to a Hash which is the main message payload. This lets you indicate the message's severity, software component origin (or some other meaning you can assign yourself), "tag" it with some component-specific code and then include component-specific data. Structured log sinks such as LogEntries.com accept logging data in this form and maintain the structure of the data, but unstructured sinks have to flatten the output. The file and stream writers are examples, so when the above line of code is run, the output is:

`WARN [2015-12-03T16:02:16.032429+13:00] Example - message: {:field_one=>"This is message field one", :field_two=>"This is message field two"}`

There are also simpler, but less flexible methods `debug`, `info` etc.; these just call `report` with a `component` value taken from the `Hoodoo::Logger` constructor and a code of `log`. The default component value is `Middleware`, giving way the logger's origins within the service middleware.

An example using [`warn`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Logger.html#method-i-warn) is:

```ruby
logger.warn( "one", "two", "three", { "four" => "five" } )
```

`WARN [2015-12-03T16:11:08.188835+13:00] Middleware - log: {"_data"=>["one", "two", "three", {"four"=>"five"}]}`

If you've run both examples above under the same logger instance, you should find file `output.log` in your present working directory that contains both of the output lines you'll have seen at the console.

### <a name="RateLimiting"></a>Rate limiting

Slow communicators cannot just accept an unbounded number of inbound log messages if they are slow to send out, because that would require an infinite sized input queue. Memory usage would be unlimited. Instead, the slow writer mechanism implements a hard cutoff on the log message queue. Once this cutoff is reached, it stops buffering messages and counts the number of dropped items.

Once the slow writer catches up and queue space becomes available, at the _next_ log message output, an additional line is written first warning about the dropped messages. It uses level `warn`, component `Hoodoo::Logger::SlowCommunicator` and code `dropped.messages`. The [slow log writer example](#SlowExample) below is used to demonstrate this behaviour.

The queue limit and counter is actually implemented right down in the slow communicator pool. Constant [`Hoodoo::Communicators::Pool::MAX_SLOW_QUEUE_SIZE`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Communicators/Pool.html#MAX_SLOW_QUEUE_SIZE) defines the maximum queue size.



## Within services

If using the [service shell]({{ site.baseurl }}/guides_0100_fundamentals.html#Shell) then Hoodoo middleware will handle logging. The bulk of the explanation for its behaviour is in RDoc under [`Hoodoo::Services::Middleware#logger`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Middleware.html#method-c-logger). The service shell's `environment.rb` sets up the log folder for file output, so apart from anything else, messages are sent to files inside a `log` folder in a Rails-like manner, using filenames of `<environment>.log` (e.g. `development.log`, `test.log`).

Your service can use the middleware's default logger as described above, or set its own complete replacement with [`Hoodoo::Services::Middleware#set_logger`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Middleware.html#method-c-set_logger). You can even create independent logger instances and use them in any way you like, though having multiple independent logs is probably a bad idea!



## Automatic middleware messages

### Default logging

The middle ware writes quite verbose `debug` level messages to aid service development and `info` level messages to aid general analytics and operations.

* Log entries describing an inbound API call use `component` = `Middleware` and `code` = `inbound`
* Log entries describing an outbound response use `component` = `Middleware` and `code` = `outbound`
* Log entries describing a successful result of an API call use a `component` named after the target resource (e.g. `Purchase`, `Version` etc.) and a `code` of `middleware_<action>` where `<action>` is one of `show`, `list`, `create`, `update` or `delete`.

There will often be _two_ inbound log messages; one is a cautious, initial secure notification that a request has arrived, but it won't risk leaking potentially sensitive information until a target resource interface has been identified and required log security (see below) ascertained. A full inbound log message may then be written, if security settings allow it.

### Secured logging

Each resource interface class that you write can override the normal full inbound/outbound URI and body payload information logged by Hoodoo to protect against sensitive information being leaked into logs. For speed, the mechanism is all-or-nothing; individual field-level JSON protection is not available.

See the RDoc information on method [`Hoodoo::Services::Interface#secure_log_for`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-secure_log_for) for more information.



## Creating new log writers

### The Communicator class family

Below the logging and [exception reporting]({{ site.baseurl }}/guides_0600_exception_reporting.html) systems is the Communicator class family. This is based around a [`Hoodoo::Communicators::Pool`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Communicators/Pool.html) of either [`Hoodoo::Communicators::Fast`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Communicators/Fast.html) or [`Hoodoo::Communicators::Slow`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Communicators/Slow.html) subclasses. The logger uses a pool of fast or slow writer instances which drive a fast or slow log writer. The communicator pool hides away the complexities of the underlying behaviour and lets log writer authors concentrate on very simple, focused writer classes.

### Log writers

Something which can operate synchronously and quickly -- for example, a writer which prints to the console or to a network connection using an internally asynchronous mechanism -- should be created as a subclass of [`Hoodoo::Logger::FastWriter`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Logger/FastWriter.html). Something which is relatively slow -- for example, a writer which writes synchronously to a hard drive or database -- should be written as a subclass of [`Hoodoo::Logger::SlowWriter`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Logger/SlowWriter.html). Be sure to check the RDoc information links given here, especially for the slow writer, since there may be restrictions or caveats of which you must be aware.

Bear in mind the mention of "an internally asynchronous mechanism" above. The LogEntries.com `le` Ruby gem sends messages out to a cloud-based service over the Internet, so a writer using this could be considered slow; but the gem does not make the caller wait for a communications round trip to the remote service when it sends out a message. It uses its own internal strategies for this. As a result, this is considered a fast writer. Implementing any otherwise-fast log writer under the slow writer class hierarchy as a precaution is typically harmless, but potentially less efficient due to the communications pool's Ruby thread overhead.

#### Unstructured ("flat") output

The stream writer and file writer loggers must take structured inbound log data and convert it to single lines in files. You can do this any way you like, but if you want consistent output across all unstructured writers, include the [`Hoodoo::Logger::FlattenerMixin`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Logger/FlattenerMixin.html). The RDoc gives full information as ever, but it boils down to calling the `flatten` method to generate the single-String output data.

#### Structured output

The [`Hoodoo::Logger::WriterMixin`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Logger/WriterMixin.html) module is included by the fast and slow writer base classes and implements the structured underlying writer method [`report`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Logger/WriterMixin.html#method-i-report) which just raises an exception. This means that, should a writer subclass author forget to write this method, attempts to use the logger would raise an exception that makes it easy to understand and address the implementation omission.

The higher level, less structured `debug`, `info`, `warn` and `error` methods all call `report` under the hood. This is implemented by the writer pool so those methods cannot be overridden by individual writers. A writer must implement `report` and only `report`.

### Examples

#### Fast writer

This writer can only print to `STDOUT`. It adds a prefix of 'Hello' to any component and 'hello.' to any code. Since it writes to standard output, it writes flat "unstructured" strings. We can define and test this with the Ruby interactive prompt, assuming the Hoodoo gem is available via:

* a service with Hoodoo in a Gemfile and `bundle install` has been run -- use `bundle exec irb` from inside the service folder, or
* system wide -- just use `irb`).

...then first, paste in the following to define the class:

```ruby
require 'hoodoo'

class HelloWriter < Hoodoo::Logger::FastWriter
  include Hoodoo::Logger::FlattenerMixin

  def report( log_level, component, code, data )
    string = flatten(
      log_level,
      "Hello#{ component }",
      "hello.#{ code }",
      data
    )

    $stdout << string << "\n"
  end
end
```

Note how the writer is responsible for outputting any end-of-line delimiter itself -- `"\n"` in this case. Next, use it:

```ruby
logger = Hoodoo::Logger.new
logger.add( HelloWriter.new )
logger.info( 'hello world' )
logger.report( :info, 'Test', 'test', { :one => 1, :two => 2 } )
```

...prints, synchronously and thus in amongst the IRb prompt's own output, these log lines:

`INFO [2015-12-04T10:20:33.265000+13:00] HelloMiddleware - hello.log: {"_data"=>["hello world"]}`<br>`INFO [2015-12-04T10:20:33.267001+13:00] HelloTest - hello.test: {:one=>1, :two=>2}`

#### <a name="SlowExample"></a>Slow writer

This writer also prints to `STDOUT`, but has a bit of a sleep before it does so! We will send a small storm of log messages to it and see what happens inside the logging system when we do that. A slow writer class is really not particularly different from any fast writer:

```ruby
require 'hoodoo'

class SleepyWriter < Hoodoo::Logger::SlowWriter
  include Hoodoo::Logger::FlattenerMixin

  # We could use "*args" here to avoid the repetition of the arguments
  # into 'flatten', but for sake of example, this is kept similar to
  # the previous fast writer code.
  #
  def report( log_level, component, code, data )
    string = flatten(
      log_level,
      component,
      code,
      data
    )

    sleep( 0.1 )

    $stdout << string << "\n"
  end
end
```

This done, send lots of messages, expecting no lengthy delays at the command prompt, but a short delay to elapse before any logging actually happens and between each message.

```ruby
logger = Hoodoo::Logger.new
logger.add( SleepyWriter.new )

1.upto( 100 ) { | count | logger.info( "Message #{ count }" ) }
```

If you run this, you'll see messages 1 through 50 printed, then nothing. The command prompt is not blocked -- press Return a couple of times to verify this -- but messages 51 to 100 see to have vanished. This is a demonstration of the [rate limiting behaviour described earlier](#RateLimiting). You might see slightly more than 50 messages successfully printed and thus slightly fewer dropped depending on scheduling of threads and the resulting rate of output versus addition, but it'll be close to that number.

While you waited for the messages to be printed, the queue would have emptied so now there's plenty of room to accept another message and thus print a warning about the dropped items. This is exactly what happens:

```ruby
logger.info( "Final message" )
```

...prints _two_ lines:

`WARN [2015-12-04T10:50:40.528032+13:00] Hoodoo::Logger::SlowCommunicator - dropped.messages: "Logging flooded - 50 messages dropped"`<br>`INFO [2015-12-04T10:50:40.630232+13:00] Middleware - log: {"_data"=>["Final message"]}`

Note the level of `warn`, component of `Hoodoo::Logger::SlowCommunicator` and code of `dropped.messages`.
