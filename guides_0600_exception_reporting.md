---
layout: default
categories: [guide]
title: Exception Reporting
---

## Purpose

Hoodoo provides support for both synchronous fast and asynchronous exception reporting mechanisms. Multiple destinations can be configured. This Guide describes the 'raw' exception reporting system and the way in which the service middleware and associated empty [service shell]({{ site.baseurl }}/guides_0100_fundamentals.html#Shell) drives it.

Exception reporting is implemented as a class-based (rather than instance-based) solution within the service middleware classes. Underpinning all reporting is the `Hoodoo::Services::Middleware::ExceptionReporting` class and its supporting class methods. The [RDoc information for this]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Middleware/ExceptionReporting.html) covers the details extensively, so the Guide will focus only on feature discovery and worked examples.

There are many similarities in the approach for both logging and exception reporting, and both use the same underlying mechanisms. Reading both guides may be useful. The exception reporting system has a more restrictive, simplified API to reduce the chances of runtime failure.



## Reporting

### Automatic reporting

#### Behaviour

The Hoodoo service middleware includes a top-level exception handler that rescues all exceptions from service implementations or the middleware itself. It has a three-stage rescue:

* The first is high level and attempts to describe the operation that was underway when things went wrong in some detail. If the normal exception handler works, the exception reporting mechanism described here will be driven normally and the normal response channels will be used, including outbound logging.

* If the middleware's primary reporting system fails, a last-chance rescue handler will attempt to at least [log the problem]({{ site.baseurl }}/guides_0500_logging.html) as an alert, then write a low-level Rack response as a 500 HTTP status code with a non-JSON body.

* If even this crashes, the middleware will not be able to log anything, but will at least try to send back the low-level Rack response.

In the unlikely event that the response to Rack causes a problem, the service would encounter an uncaught exception.

In the first ("normal", working) case, the returned response to callers is a 500 HTTP status code with a [well-formed Errors payload]({{ site.custom.api_specification_url }}) containing a `platform.fault` error and exception details in the payload. This includes a backtrace in non-production environments.

#### Configured exception reporters

No exception reporting endpoints are configured by default. Exceptions are returned via [Errors instances in the returned payload]({{ site.custom.api_specification_url }}) as described above, but not sent anywhere else. The [service shell]({{ site.baseurl }}/guides_0100_fundamentals.html#Shell) enables reporters using files inside `config/initializers`; reporters include classes which send data to [Airbrake](https://airbrake.io) and/or [Raygun](https://raygun.io). For both of those you'd need to sign up for an account with the relevant service(s), get a reporting API key / token and fill that in to the relevant section of the initializer file according to the commented instructions inside those files. As an example, the Raygun reporter, if enabled, would look rather like this:

```ruby
require 'raygun4ruby'

Raygun.setup do | config |
  config.api_key = '1234567890ABCDEF'
end

Hoodoo::Services::Middleware::ExceptionReporting.add(
  Hoodoo::Services::Middleware::ExceptionReporting::RaygunReporter
) unless Service.config.env.test? || Service.config.env.development?
```

The service's `Gemfile` would need to include the `raygun4ruby` gem and `bundle install` would have to be run so that this were available for the API key configuration. Then the reporter class is simply added as shown. The environment exceptions are present to prevent a service running on a local machine for development or test from broadcasting exceptions to the Raygun account -- of course if you _wanted_ that you could just omit the exception case.

### Manual reporting

A service can choose to broadcast through the exception reporting mechanism either by simply raising an exception itself and letting the middleware catch it, or driving the reporter explicitly. Since it is a singleton, you access the middleware-wide exception reporting engine simply via the `Hoodoo::Services::Middleware::ExceptionReporting` class within a service's resource implementation code. See RDoc for the [`report`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Middleware/ExceptionReporting.html#method-c-report) and [`contextual_report`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Middleware/ExceptionReporting.html#method-c-contextual_report) methods for details.

#### Basic API

The original exception reporting engine includes a basic API that just takes exception and _optional_ Rack environment details. This is easy to drive from both within a service's request/response cycle, or outside it, with no particular middleware dependency.

For example:

```ruby
class FooImplementation < Hoodoo::Services::Implementation
  def show( context )

    # ...encounter some exceptional condition severe enough to need
    # explicitly reporting but not raising/throwing then...

    Hoodoo::Services::Middleware::ExceptionReporting.report(
      RuntimeError.new( 'Something bad happened' ),
      context.owning_interaction.rack_request.env
    )

  end
end
```

Note how your service can access the Rack request as a high level object through `context.owning_interaction.rack_request` and thus the environment Hash required for `report` from its `env` property.

* [Hoodoo::Services::Context#owning_interaction`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Context.html#attribute-i-owning_interaction)
* [`Hoodoo::Services::Middleware::Interaction#rack_request`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Middleware/Interaction.html#attribute-i-rack_request)
* [`Rack::Request#env`](http://www.rubydoc.info/gems/rack/Rack/Request#env-instance_method)

#### Contextual API

From Hoodoo v1.3.0 onwards, an additional reporting engine takes a mandatory context parameter and uses this to provide substantially more detailed exception reporting, subject to support for arbitrary user data in the exception reporting endpoint. The out-of-box example implementations for Airbrake (via its `session` API option key) and Raygun (via its `custom_data` API option key) make use of this. Other endpoint subclasses do not have to support this method; if the reporting subclass doesn't implement the contextual API, the Rack environment data is extracted from the context information and the system falls back to the basic API described above.

```ruby
class FooImplementation < Hoodoo::Services::Implementation
  def show( context )

    # ...encounter some exceptional condition severe enough to need
    # explicitly reporting but not raising/throwing then...

    Hoodoo::Services::Middleware::ExceptionReporting.contextual_report(
      RuntimeError.new( 'Something bad happened' ),
      context
    )

  end
end
```

This more informative method is recommended over the basic API when writing new service implementation code.



### Rate limiting

Like logging, exception reporting is based on [`Hoodoo::Communicators::Pool`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Communicators/Pool.html). Unlike logging, _all_ reporters are considered "slow communicators" and run on a Ruby thread with a queue size-based rate limit on incoming reports.

See the [relevant section of the Logging Guide]({{ site.baseurl }}/guides_0500_logging.html#RateLimiting) for more information about rate limiting -- the description there applies equally to exception reporting.



## Creating new reporters

Exception reporters are driven from a [`Hoodoo::Communicators::Pool`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Communicators/Pool.html) directly. A reporter is a subclass of somewhat epically namespaced class [`Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Middleware/ExceptionReporting/BaseReporter.html), **which is a singleton** (so your reporter subclass will be too); this in turn is a subclass of [`Hoodoo::Communicators::Slow`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Communicators/Slow.html). _All_ exception reporters are treated as slow communicators and are run in a Ruby thread. Be sure to read the RDoc links above to understand more about communications pools and the implications of executing as a slow communication subclass.

After that, it's very easy; you implement the [`Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter#report`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Middleware/ExceptionReporting/BaseReporter.html#method-i-report) and optionally the [`Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter#contextual_report`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Middleware/ExceptionReporting/BaseReporter.html#method-i-contextual_report) methods, remembering that your class is operating as a singleton. The design pattern behind the approach was taken with Airbrake and Raygun in mind as initial implementations, so your singleton is automatically instantiated without parameters. If you need any configuration and can't use class level storage, you could (for example) read environment variables or a YAML file inside a custom -- albeit still parameter-free -- `initialize` method.

### Example

Suppose our "reporter" just prints to `STDOUT` for simplicity, but waits a couple of seconds before doing it just to prove that slow reporters do indeed run asynchronously! We can define and test this with the Ruby interactive prompt, assuming the Hoodoo gem is available via:

* a service with Hoodoo in a Gemfile and `bundle install` has been run -- use `bundle exec irb` from inside the service folder, or
* system wide -- just use `irb`).

...then first, paste in the following to define the class:

```ruby
require 'hoodoo'

class StdoutReporter < Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter

  # This is where you could add custom configuration, if you didn't
  # have an Airbrake/Raygun-like model where an underlying support
  # gem were responsible for configuration via e.g. an addition to
  # the service shell's "config/initializers" collection. Otherwise,
  # just don't bother implementing the method at all.
  #
  def initialize
    puts( "Hello!" )
  end

  def report( exception, rack_env )
    sleep( 2 )

    puts( "Exception encountered!" )
    puts( "=" * 80                 )
    puts( exception.inspect        )
    puts( "-" * 80                 )
    puts( rack_env.inspect         )
  end
end
```

Next, tell the exception reporting system about it:

```ruby
Hoodoo::Services::Middleware::ExceptionReporting.add( StdoutReporter )
```

Note how the `Hello!` message gets printed due to automatic instantiation of the singleton you defined. Finally, report an exception to see it in use:

```ruby
exception = RuntimeError.new( "Hello world!" )
Hoodoo::Services::Middleware::ExceptionReporting.report( exception )
```

If you paste that into the Ruby interactive shell you'll see the usual output from that shell and get the command prompt back, because the reporter is running on a background thread. After a couple of seconds the report will be made:

```
Exception encountered!
================================================================================
#<RuntimeError: Hello world!>
--------------------------------------------------------------------------------
nil
```



## Combination example

We can define a very minimal service that generates an exception for Hoodoo to catch, or reports one manually, all in one Ruby file. Make sure the Hoodoo gem is installed if you want this to run. See the [Fundamentals Guide]({{ site.baseurl }}/guides_0100_fundamentals.html) for assistance if need be.

```ruby
require 'rack'
require 'hoodoo'

# The implementation will raise an exception if you call 'show',
# or raise a manual exception for 'list'.
#
class ExceptionImplementation < Hoodoo::Services::Implementation
  def show( context )
    raise "You tried to show '#{ context.request.ident }'"
  end

  def list( context )
    Hoodoo::Services::Middleware::ExceptionReporting.report(
      RuntimeError.new( 'Manually reported from #list' ),
      context.owning_interaction.rack_request.env
    )

    # Exception was reported but not thrown, so this code will run.
    context.response.set_resources( [] )
  end
end

class ExceptionInterface < Hoodoo::Services::Interface
  interface :Exception do
    endpoint :exceptions, ExceptionImplementation
    public_actions :show, :list
  end
end

class ExceptionService < Hoodoo::Services::Service
  comprised_of ExceptionInterface
end

# Simplified version of the reporter example from earlier.
#
class StdoutReporter < Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter
  def report( exception, rack_env )
    puts( "Exception encountered!" )
    puts( "=" * 80                 )
    puts( exception.inspect        )
    puts( "-" * 80                 )
    puts( rack_env.inspect         )
  end
end

Hoodoo::Services::Middleware::ExceptionReporting.add( StdoutReporter )

# As in the Fundamentals Guide examples, this is a hack just for the example
# to ensure it works when you have Active Record present in your gems.
#
Object.send( :remove_const, :ActiveRecord ) rescue nil

# Finally, run the service on port 9292 using Rack.
#
builder = Rack::Builder.new do
  use( Hoodoo::Services::Middleware )
  run( ExceptionService.new )
end

Rack::Handler::Thin.run( builder, :Port => 9292 )
```

Copy the above code into file `service_exception.rb` and run it:

```sh
ruby service_exception.rb
```

In another shell (terminal window), we can talk to it with `curl` and examine the results in the shell that's running the service. First, run the `show` action to see Hoodoo's handler in action.

```sh
curl http://127.0.0.1:9292/v1/exceptions/helloworld \
     --header 'Content-Type: application/json; charset=utf-8'
```

The response returned to `curl` (reformatted) is:

```json
{
  "created_at": "2015-12-04T01:50:43Z",
  "errors": [
    {
      "code": "platform.fault",
      "message": "You tried to show 'helloworld'",
      "reference": "You tried to show 'helloworld',service_exception.rb:9:in `show' [...backtrace snipped...]"
    }
  ],
  "id": "30eaec07ab3f48a4974bb2f8792d1914",
  "interaction_id": "bf9f2d8427b74f4a990b6631587ec480",
  "kind": "Errors"
}
```

Note the backtrace inclusion since by default the service will be running in development mode. Meanwhile, in the shell that's running the service, amongst the logging data you should see the custom exception reporter's output:

```
Exception encountered!
================================================================================
#<RuntimeError: You tried to show 'helloworld'>
--------------------------------------------------------------------------------
{...Rack environment data snipped...}
```

Next, the `list` action that manually reports an exception but then finishes normal processing and returns an empty list:

```sh
curl http://127.0.0.1:9292/v1/exceptions \
     --header 'Content-Type: application/json; charset=utf-8'
```

The response returned to `curl` is simply:

```json
{"_data":[]}
```

...while in amongst the logging data, the reporter will have printed its message in the service's shell:

```
Exception encountered!
================================================================================
#<RuntimeError: Manually reported from #list>
--------------------------------------------------------------------------------
```

Finally, just to demonstrate the non-backtrace behaviour in Production, stop the service with `Ctrl+C` and re-run it in production mode:

```sh
RACK_ENV=production ruby service_exception.rb
```

Re-run the `show` call via `curl` in another shell:

```
curl http://127.0.0.1:9292/v1/exceptions/helloworld \
     --header 'Content-Type: application/json; charset=utf-8'
```

The (reformatted for legibility below) response is similar to before, but without the backtrace:

```json
{
  "created_at": "2015-12-04T02:05:11Z",
  "errors": [
    {
      "code": "platform.fault",
      "message": "You tried to show 'helloworld'",
      "reference": "You tried to show 'helloworld'"
    }
  ],
  "id": "4311aced50814b45ab8a46fa9353991c",
  "interaction_id": "b92c13332f0247e5b7dc5e31e7a4d33d",
  "kind": "Errors"
}
```

In the shell running the service, console logging is suppressed for production mode but the exception reporter still prints the expected report. Remember, although the Hoodoo middleware is responsible for including or omitting a backtrace in the response it sends back to the API client, it's up to individual exception reporter classes to decide whether to include or omit this when reporting exceptions to wherever they are sent. In this simple example, the custom reporter doesn't do anything different for production or development.
