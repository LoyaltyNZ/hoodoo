---
layout: default
categories: [guide]
title: Fundamentals
---

## Purpose

This guide gives an introduction to basic Hoodoo API concepts, shows how to write a "hello world" service without a persistence back-end and describes template service shell.

> Although these Guides are believed accurate at the time of writing, always remember that the [Hoodoo RDoc information]({{ site.custom.rdoc_root_url }}/index.html) is the source of truth for Hoodoo's public API.

## Concepts

### Nomenclature

Hoodoo provides a Ruby programming framework which describes various entities:

* An API consists of various _resources_.
* Each resource has an _interface_ and an _implementation_.
* A _service application_ (or just "service") is comprised of one or more resource interfaces.
* Resources can easily call one another, so you can arrange all resources into one single big service, split everything into a one-per-resource microservice-like arrangement, or anything in between.
* "The platform" is the assembly of resource interfaces your service(s) provide, viewed as a single coherent API-based software platform.

### Actions

Hoodoo supports exactly 5 _actions_, mapped by HTTP verb:

* `GET` with no additional path parameters maps to `#list`
* `GET` with any additional path parameters maps to `#show`
* `POST` expects no additional path parameters and maps to `#create`
* `PATCH` expects additional path parameters and maps to `#update`
* `DELETE` expects additional path parameters and maps to `#delete`

The use of the verb `PATCH` indicates that both partial or full resource updates are supported. Omission of a field in an inbound payload means "do not change".

At a minimum, a resource implementation consists of between one and five instance methods of a `Hoodoo::Services::Implementation` subclass, one for each supported action. All have identical input parameter signatures but differing requirements for their side effects.

### Routing

The interface for a resource names that resource and declares where its endpoint is, in terms of a URI; this is the only sort of routing you get in Hoodoo. Each interface is versioned, with a default version of 1. An example path to a resource `Foo` at path `foos` in version `2` would be: `api.test.com/v2/foos`.

Hoodoo uses Rails-like pluralisation for its default routing discovery convention in the Ruby client side component, `Hoodoo::Client`. If you're intending to use this or something like it, sticking to [ActiveSupport pluralisation rules](http://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-pluralize) for mapping between resource names and endpoint locations will make your life easier.

### Content types

Hoodoo _requires_ the caller to specify the content type and encoding of inbound data. At the time of writing only JSON and UTF-8 are supported. Every Hoodoo inbound API call _must_ include a `Content-Type` HTTP header with a value of `application/json; charset=utf-8`. Without this, Hoodoo will reject the call. Support for other request/response content types may be added in future.

### Error reporting

Hoodoo reports any error via a non-2xx HTTP response code and representation of an Errors JSON resource. This is described in the [Hoodoo API Specification](https://github.com/LoyaltyNZ/hoodoo/tree/master/docs/api_specification/) -- basically it is a valid resource representation and contains details of one or more errors that occurred during processing. For example:

```json
{
  "id": "a73760e4458946519d18beeddb7c781d",
  "kind": "Errors",
  "created_at": "2015-08-04T01:20:53Z",
  "interaction_id": "fc258127cd354115ad77dc6a4b6470c3",
  "errors": [
    {
      "code": "platform.malformed",
      "message": "Content-Type 'application/xml; charset=utf-8' does not match supported types '[\"application/json\"]' and/or encodings '[\"utf-8\"]'"
    }
  ]
}
```

Any exception in service code is caught and reported back via an error instance as shown above. Backtraces are included in non-production environments only. For more about this, please see the [Exception Reporting Guide]({{ site.baseurl }}/guides_0600_exception_reporting.html).

### Environment variables

Since Hoodoo is based on Rack, you use variable `RACK_ENV` as you would use, say, `RAILS_ENV` for testing and can use things like `rackup` (with an appropriate `config.ru` file present, see later) to start it. For example, you might start your service in production mode as follows:

```sh
RACK_ENV=production bundle exec rackup
```

Various other environment variables consulted by Hoodoo are described in the [Environment Variables Guide]({{ site.baseurl }}/guides_1000_env_vars.html).

### API design

It is _very strongly_ recommended that resource API designers opt for backwards compatibility at all times. Implement future extensions to an existing API either via optional fields or entirely new resources, such that existing client code can continue to work without modification. Client authors usually have better things to do with their time than repeatedly rewrite their existing code base to adapt to the whims of incompatible API changes!

Resources have an associated integer major version number as part of the primary routing mechanism. When necessary, major API changes for a resource should be introduced using a new major resource version.



## A Minimal Service

Although the _service shell_ is the recommended way to get started with a new service ([see later](#Shell)), there's nothing much magic about the way that Hoodoo uses Ruby subclasses and files. As shown on the [Home page]({{ site.baseurl }}/), you can bring one up a simple resource with just a single Ruby file. Here, we look at that file more closely, section by section.

> A much more fully-featured example using service shell, persistence and presentation features is given in the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html) but this minimal example is a good place to start to undestand the basics.

### Required gems

Since this is a minimal example, we aren't using Bundler or a Gemfile but you can do so if you wish; otherwise, manually install Thin, Rack and Hoodoo directly:

```sh
gem install thin
gem install rack
gem install hoodoo
```

### The service code

The rest of this example all goes into a single Ruby file. Call it anything you like, e.g. `service.rb`.

Obviously, the Hoodoo service file needs to start by including Hoodoo itself. Since we are going to use Rack to start up the Rack application directly within this single file, we also need Rack -- and that's all. **Always include Rack first** [[1]]({{ site.custom.rdoc_root_url }}/files/lib/hoodoo/services/middleware/rack_monkey_patch_rb.html), [[2]]({{ site.custom.rdoc_root_url }}/classes/Rack/Server.html).

```ruby
require 'rack'
require 'hoodoo'
```

### The implementation class

Hoodoo _service_ classes refer to interface class(es) for the resource(s) hosted by that service. In turn, the _interface_ classes refer to the implementation class(es). That means -- no matter what order we actually _write_ the code -- that we need to _define_ the implementation class first in the parse order. Class names are entirely up to you, though the pattern of `FooImplementation` and `FooInterface` is recommended.

```ruby
class TimeImplementation < Hoodoo::Services::Implementation
  def show( context )
    context.response.set_resource( { 'time' => Time.now.utc.iso8601 } )
  end
end
```

You can define whatever `private` or `protected` methods you want, except for names `#show`, `#list`, `create`, `#update` and `#delete`. These are reserved and called by Hoodoo in response to incoming API requests. They all have the same signature shown above, with the `context` variable, which provides information on the inbound request and is used to define your response. The `context` object is also used to request an endpoint for a resource-to-resource call -- an _inter-resource_ call -- via its `#resource` method. For more, see the [RDoc page for the Context class]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Context.html).

Method `#verify` is also reserved; see the [RDoc page for the Implementation class]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Implementation.html) and the [Security Guide]({{ site.baseurl }}/guides_0200_security.html) for full information.

> **Important:** Hoodoo specifies that a representation of a resource is returned in API responses for _all_ actions.

This means that if successful, the implementations of `#show`, `create`, `#update` and `#delete` _must_ call `context.response.set_resource` with a single resource representation before exiting, as shown above. The implementation of `#list` _must_ call `context.response.set_resources` (plural) with an Array of resource representations before exiting. See the [RDoc page for the Response class]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Response.html) for details (noting that `#set_resource` is an alias of `#body`).

In this example we are just returning an arbitrary Hash, but resource representations really should be properly rendered through the Presenter layer to ensure consistency and accuracy. The DSL for this layer can also be used to specify (and Hoodoo will then automatically validate) inbound creation or update payloads. For information on Presenters, see the [Presenters Guide]({{ site.baseurl }}/guides_0400_presenters.html).

If the implementation fails, it should add one or more error messages to its response object via the `#add_errors` method. If the implementation throws an uncaught exception, Hoodoo itself will catch it and return a well-formed HTTP 500 / `platform.fault` error.

> **Important:** While many parts of Hoodoo accept parameters as Symbols or Strings, for inbound payloads and rendered data, Hoodoo does _not_ use an "indifferent access" Hash. Keys in outbound data **must be Strings** and keys in all inbound data **will be Strings**.

### The interface class

The interface class can describe your resource in some detail, but the minimal case is simple:

```ruby
class TimeInterface < Hoodoo::Services::Interface
  interface :Time do
    endpoint :time, TimeImplementation
    public_actions :show
  end
end
```

The `interface` method takes the name, as a Symbol or String, of the resource -- here, `:Time` -- and a block which uses the interface DSL to describe the resource. In this minimal case, we declare that the resource is located at an endpoint including the URI fragment `time` (again given as Symbol or String) and give the implementation class directly. The interface version is not specified to defaults to `1` -- the resource will therefore be found at a URI path of `.../v1/time`.

All service actions by default are protected by a security layer and require a session to access them. See [Security Guide]({{ site.baseurl }}/guides_0200_security.html) for details. If your service implements all actions, it need declare nothing. If it defines a subset of session-protected actions, it can use the `actions` method to list them. If it defines any public actions -- these can be called with no session -- then it uses the `public_actions` method, as shown here.

The full range of DSL "commands" available within the `interface` block are described by the [RDoc page for the Interface class]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html). The suggested reading order is:

1. `#interface` (as a refresher)
2. `#endpoint` and `#version`
3. `#actions` and `#public_actions`
4. `#embeds` if you know about _embedding_ -- see the [Hoodoo API Specification]({{ site.custom.api_specification_url }}) for details
5. `#to_list` to specify more about how you handle lists (index views), such as additional sort keys, or search and filter information -- see the [Hoodoo API Specification]({{ site.custom.api_specification_url }}) for details
6. `#to_create`, `to_update` and `update_same_as_create` if you want validation of inbound create/update payloads; see also the [Presenters Guide]({{ site.baseurl }}/guides_0400_presenters.html)
7. `#secure_log_for` if you have sensitive data inbound or outbound that shouldn't be logged; see also the [Security Guide]({{ site.baseurl }}/guides_0200_security.html) and the [Logging Guide]({{ site.baseurl }}/guides_0500_logging.html)
8. `#errors_for` if you want to add custom error messages to responses; the [Hoodoo API Specification]({{ site.custom.api_specification_url }}) lists the API defaults and the [RDoc page for the Errors class]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Errors.html) to understand what's going on behind the scenes (see in particular its `#add_error` method )
9. `#additional_permissions_for` if you want to make inter-resource calls and require additional permissions in addition to those offered by the inbound caller's session, you request them here. See the [Security Guide]({{ site.baseurl }}/guides_0200_security.html) for details.

> The more complete and precise your interface declaration, the greater the safety net that Hoodoo provides. Your service can benefit from up-front validation at the resource description level of inbound data, not get called for actions it doesn't implement, participate in the security model and so-on all from a few simple DSL calls. Your API will end up more robust and more consistent. It is best practice to describe interfaces thoroughly.

#### Public actions and sessions

Although your service can declare actions that are accessible from anyone at any time, you'll probably want to prevent arbitrary, unauthorised calls. This is handled by _sessions_. Any protected action needs a valid session in order to be processed.

In a `RACK_ENV` mode of `development` or `test`, Hoodoo uses an internal test session which permits any access to any resource. In other environments, Hoodoo looks sessions up in [Memcached](http://memcached.org). You must set environment variable `MEMCACHED_HOST` for your service to run successfully (e.g. `MEMCACHED_HOST=127.0.0.1:11211 RACK_ENV=production bundle exec rackup`).

The session system is described in full in the [Security Guide]({{ site.baseurl }}/guides_0200_security.html).

### The service class

The service class is simple; it just declares all resource interfaces that exist within this service application.

```ruby
class TimeService < Hoodoo::Services::Service
  comprised_of TimeInterface
end
```

You can use a comma-separated list for the `comprised_of` call and/or multiple `comprised_of` calls (according to your preferred coding style) to make the declarations. For more, see the [RDoc page for the Service class]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Service.html)

If intending to wrap up several resources within a single service, try to name your service class according to the overall intent. For example, a service class comprised of `Credit` and `Debit` resources might be called `FinancialService`.

### Active Record

In the simple example here, we aren't using any persistence layer such as a database. In particular, we are not using [Active Record](http://guides.rubyonrails.org/active_record_basics.html). If you don't have that installed as a gem under your current Ruby environment, there is no problem. If the Active Record constant is defined however, Hoodoo detects this and activates its Active Record support code, described in the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html). An attempt to start up the example service would fail as Hoodoo would attempt to connect to a database without any connection configuration. So, just in case, and _purely for the purposes of making this example work_ even if you have Active Record present, we add a hack:

```ruby
# This is a hack for the example and needed if you have Active Record present,
# else Hoodoo will expect a database connection.
#
Object.send( :remove_const, :ActiveRecord ) rescue nil
```

...and simply un-define the entire Active Record namespace from Object, so that Hoodoo doesn't detect it.

### Bring-up with Rack

Finally, we need to tell Rack about our Hoodoo-based Rack application and start it. Here, we tell Rack to use the Thin web server on port 9292:

```ruby
builder = Rack::Builder.new do
  use( Hoodoo::Services::Middleware )
  run( TimeService.new )
end

Rack::Handler::Thin.run( builder, :Port => 9292 )
```

This is just one of many ways to bring up a Rack application; there are many tutorials and bits of documentation about Rack available online if you search around, plus of course the core [Rack documentation](https://rack.github.io) itself.

### Running the service

Now you have the service declarations and Rack startup all inside a file called (say) `service.rb` and gems installed, so you can start the service easily -- add `bundle exec` in front of the command if you used Bundler for the gems:

```sh
ruby service.rb
```

The service is now ready for use:

```sh
curl http://127.0.0.1:9292/v1/time/now \
     --header 'Content-Type: application/json; charset=utf-8'
```

```json
{"time":"2015-08-03T02:31:34Z"}
```

Don't forget to include the `Content-Type` header exactly as shown above for all API calls.



## Searching, filtering and embedding

Lists of resources can be searched (include-on-match) or filtered (exclude-on-match). It's up to the [class describing the interface]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html) of a resource to declare the things it allows for these operations, if anything. Likewise, a resource might also allow someone to request that its representation includes other embedded data -- usually, some important related resource -- to make life easier for callers; one call instead of two, that kind of thing.

The caller-side implementation of this is all described by the [Hoodoo API Specification]({{ site.custom.api_specification_url }}). As mentioned earlier, the code implementation is managed via the `#to_list` DSL -- see [`to_list`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface.html#method-i-to_list) and the [ToListDSL class]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Interface/ToListDSL.html) in RDoc for details.

It's important to be aware of the options for searching and embedding in particular, as efficient API design can depend upon it -- especially once inter-resource calls get involved.



## Inter-resource calls

### Overview

Often, one resource will want to call another resource as part of its general operation. If the two resources are running inside the same service application, you _could_ just directly access the data model underneath the target resource. Unfortunately this can introduce security or scoping errors and breaks encapsulation, coupling the two resources together forever inside the same service application.

Instead, it's better to use an _inter-resource call_, a high level construct which amounts to -- via several layers of abstraction -- a local method to a resource in the same service application, or a real remote call to another service application if required. The semantics for both are the same; resources always "look" as if they're remote.

### Code

Suppose a Clock resource were implemented in terms of a Time and a Date resource. To show the Clock, it has to show the Time and the Date internally.

```ruby
def show( context )
  time_resource = context.resource( :Time, 1 )
  date_resource = context.resource( :Date, 1 )

  time = time_resource.show( '<id>' ); return if time.adds_errors_to?( context.response.errors )
  date = date_resource.show( '<id>' ); return if date.adds_errors_to?( context.response.errors )

  context.response.set_resource(
    {
      'it_is' => time[ 'time' ] + " on " + date[ 'date' ]
    }
  )
end
```

The interface is exactly like `Hoodoo::Client`, [which has its own Guide]({{ site.baseurl }}/guides_0800_hoodoo_client.html). You first ask for an endpoint for a given resource and API version (the default is `1`). Then you make calls through this endpoint following the familiar action names -- `show`, `list`, `create`, `update` or `delete`. The [Hoodoo::Client Guide]({{ site.baseurl }}/guides_0800_hoodoo_client.html) gives more information about the parameters and options for those methods.

Every time you make an inter-resource call you _MUST_ always check for errors in the result. There are two ways to do this. One is as shown above; it is an ugly design pattern because it mutates its input parameter, but it leads to terse code:

```ruby
result = some_resource.action( parameters )
return if result.adds_errors_to?( context.response.errors )
```

This takes any errors in `result`, adds them to your `context.response.errors` collection and returns if any were added; else it continues and you can examine `result` as if it were an Array or Hash containing the call's expected on-success data. A cleaner pattern avoids input parameter mutation at the expense of slightly more verbose code:

```ruby
result = some_resource.action( parameters )

context.response.add_errors( result.platform_errors )
return if context.response.halt_processing?
```

Here, we get the response object to add to its own errors collection any other errors from the collection in `result.platform_errors` (if the result's platform errors collection is empty, nothing happens). Then we exit if the response now indicates an error condition; that's also the idiomatic pattern for data level validation and other error conditions (e.g. see the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html)).

For more on these two approaches, see the [RDoc documentation for `platform_errors`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Services/Context.html).

### Performance

#### Minimise inter-resource calls

When an inter-resource call is talking to a "locally" implemented resource -- one in the same service application -- there's some overhead involved in constructing the request so that the target resource "thinks" it's just receiving any normal call and in processing the result, but this isn't too severe. Ultimately it's still just a series of local method calls. The overhead is worthwhile given the resulting simplicity of service implementation, resource decoupling and inherent reliance (without code duplication) on all of the existing security in the target resource's implementation.

When an inter-resource call is talking to a remotely implemented resource, the overhead can be significant; HTTP calls, AMQP messages or other wire protocols will be involved and the 'other end' may respond slowly.

With this in mind, minimising the inter-resource call count is a good idea. Construct your APIs such that a target resource does as much as possible in one call to ease the burden on the upstream resource. This improves internal performance and potentially provides extra facilites that all API users of the target resource might find valuable.

#### The embedding problem

When someone asks for a list of some resource and wants the result to include some other sub-resource embedded in the response, it's often due to a desire to offer a resource-level representation of relational data. For example, a Member might belong to an Account. Someone might list Accounts, asking to embed the list of Members -- if your API supported that.

One obvious implementation for Account would be to get a page of list results of Accounts and iterate over that list. For each one, you'd ask for a list of Members where the member account ID matched the list entry's ID (e.g. via a supported list item search key of `account_id`). This would work, but be slow and scale poorly. A list page of 500 Accounts could result in 500 inter-resource calls for Members!

Work around this with API design on the target, embedding resource side -- in this example, Member; here, we could simply support a comma-separated list of account IDs via an `account_ids` (plural) parameter. The Account resource gets its list, assembles the IDs of the list entries into a query string, then makes just the one inter-resource call to get associated Members. This is still not without overhead of course; now it must hold not only the list of Accounts but also the big list of Members in memory, then embed the Member data into the Account list by walking the Account list and matching the IDs in the Members list. It may need to call the Member service again for further pages of Member data too, but you can tune the page size to balance the memory requirement against inter-resource call overhead.

### Running many services locally

If you have split your resources across multiple service applications, you may want to run those all locally for easy development. There are many ways to do this, but probably the easiest is just to bring up services using `guard` which starts them on randomised spare ports. If you are developing a particular resource endpoint, bring the containing service up last, on a well known port, so API calls from the likes of `curl` or [Postman](https://www.getpostman.com) don't need to be set up with configurable port numbers.

For example, suppose you are writing `service_new` and this makes calls to resources hosted in `service_a` and `service_b`.

```sh
# In one terminal...
cd service_a
bundle exec guard
# In another terminal...
cd ../service_b
bundle exec guard
# Then in a third...
cd ../service_new
PORT=9292 bundle exec guard
```

This works because Hoodoo includes a Distributed Ruby (DRb)-based discovery engine that's activated by default for local development. Whenever a service launches for the first time, the Hoodoo DRb registry is run in the background and then keeps running, taking note of the resource endpoints declared by each service when run and the port on which it has been launched. This means inter-resource calls should "just work" both locally and remotely, provided that the service in question is up.

If you have any trouble, shut down your services then kill the DRB daemon. You might find more than one is running, or that it has become confused about port numbers after a few service restarts. On Mac OS X, the following command will list them all:

```sh
ps -Af | grep ruby | grep drb_server
514102323 36434   1   0 Mon04pm ??   0:02.72 /Users/user/.rbenv/[...]/by_drb/drb_server_start.rb
514102323 66598   1   0 26Nov15 ??   0:02.06 /Users/user/.rbenv/[...]/by_drb/drb_server_start.rb
```

...so here it's obvious that two discoverers have ended up running. Shut down any running services and kill the discoverer daemons with `kill <pid>` (e.g. for the above cases - `kill 36434; kill 66598`). When you restart the services afterwards, you should find that only one server is running.



## <a name="Shell"></a>The Service Shell

Hoodoo has no opinions on _how_ you arrange your code, it just needs the service's various subclasses defined appropriately. Although you can do the hard work of structuring a bespoke service layout, it's often easier to start from the "service shell" -- a template for new services.

### Creating a new Service

Just as you can create a skeleton Rails application using the `rails` command, so you can create a skeleton Hoodoo service using the `hoodoo` command. With the Hoodoo gem installed:

```sh
hoodoo service_foo
```

...will create a new service called "Foo" in a folder called `service_foo` by cloning an empty shell from GitHub, removing the `.git` folder and renaming generic name placeholders where appropriate.

Remember, you can have one service for each resource you write, or put several resources into a single service. It helps to have some rough idea about how you want to proceed at the start, so that your service can have a more appropriate name that's less likely to be a source of confusion in future, as you develop more resource endpoints.

> If you want to customise the service shell and use that customised copy for future services, fork the shell and point Hoodoo at the fork in the `hoodoo` command. See `hoodoo --help` for details.

### File and folder layout

This section is correct at the time of writing and will always be broadly correct, though there may be small changes/additions that happen over time in the shell code in Git which don't necessarily get immediately reflected in this Guide. The root folder of the shell contains a `README.md` which can be consulted first, before being updated with your service-specific "read me" information.

#### Basic setup

```
├── CHANGELOG.md - You should keep this up to date!
├── Gemfile      - For Bundler
├── Gemfile.lock - For Bundler
├── Guardfile    - For using 'guard'; see README.md and read Guardfile
├── Rakefile     - For 'rake' - see "bundle exec rake --tasks"
├── README.md    - You should update/modify this as needed
```

Much of the root folder contains fundamental prerequisites. As you'll see from reading the `Gemfile`, [Active Record](https://rubygems.org/gems/activerecord/versions/4.2.3) and [ActiveSupport](https://rubygems.org/gems/activesupport) are included as the database ORM and for general utility use. They function well outside of Rails and provide a familiar pattern for the persistence layer which helps service authors who would otherwise be in initially an entirely unfamiliar API world of Hoodoo. You can remove these if you want though.

When you're happy with the Gemfile, don't forget to:

```sh
bundle install
```

...so that you can use `bundle exec rake...` and similar thereafter.

> **Important:** The service shell is designed with a minimal useful gem footprint. Reduction of external dependencies is useful for security and manageability of your service. _You should run `bundle update` often!_

#### Optional setup

Some things in the root folder are helper files for particular tools, which are only of interest if you use those tools -- e.g. local Ruby version via [RBEnv](https://github.com/sstephenson/rbenv), [Travis](https://travis-ci.org) for CI, [Docker](https://www.docker.com) for deployment and so-on. You can ignore many of the configuration files when they're tool-specific. The Docker workflow and [Git](#https://git-scm.com) tagging in particular may not suit your approach or organisation even if you do use Docker and Git.

```
├── .dockerignore             - Useful if you use Docker
├── .gitignore                - Useful if you use Git
├── .ruby-version             - Useful if you use RBEnv
├── .travis.yml               - Useful if you use Travis
│
├── VERSION                   - Optional Git workflow - update via 'bin/version_bump'
├── bin
│   ├── generators
│   │   ├── classes           - Folder with supporting code for generators (see below)
│   │   ├── effective_date.rb - Effective dating generator (see below)
│   │   └── templates         - Folder with supporting templates for generators
│   └── version_bump          - Update VERSION, does tagging etc. in Git; see script
│                               for details.
```

The `bin` folder contains optional helpers.

* `ruby bin/version_bump` offers a non-semantic `major.minor` Git workflow approach to overall service application versions, updating `VERSION`, introducing `release/n` branches for major versions in `n`and `vN.M` tags for major version `N` and minor version `M`.
* `ruby bin/generators/effective_date.rb <args>` -- see the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html) and in particular [the section on 'Dating']({{ site.baseurl }}/guides_0300_active_record.html#Dating) for details.

#### Database and environments

The shell is more "opinionated" than Hoodoo by necessity. It needs to know where it's going to include files, the requirement order and so-on, and where to look to get everything set up for running under Rack locally, or in deployed environments over conventional HTTP or HTTP-over-[AMQP](https://www.amqp.org) via [Alchemy](https://github.com/LoyaltyNZ/alchemy-amq). A Rails-like configuration approach is taken with a `config` folder containing database information, environment-specific files -- remember, that's `RACK_ENV`, **NOT** `RAILS_ENV`! -- and the `initializers` folder for custom startup code. It contains out-of-box ways to easily _optionally_ enable [Raygun](https://raygun.io), [Airbrake](https://airbrake.io) and/or [NewRelic](https://newrelic.com).

The Shell introduces the idea of three environments:

* `RACK_ENV=test` -- applies while tests are running only
* `RACK_ENV=development` -- familiar, Rails-like local development
* `RACK_ENV=production` -- again familiar, fully-tested production code

You can add new environments just by using the right `RACK_ENV` value and, optionally, adding an appropriately named file into the `environments` folder.

```
├── config
│   ├── database.yml       - Same as the equivalent file in Rails
│   ├── environments
│   │   ├── development.rb - See the contents of these files for details.
│   │   ├── production.rb  - Usually, there are very few environment-specific
│   │   └── test.rb        - pieces of information needed by a service.
│   ├── initializers       -
│   │   ├── airbrake.rb    - Uncomment and add your Airbrake API key if need be
│   │   ├── new_relic.rb   - Uncomment and ensure "newrelic.yml" is filled in
│   │   └── raygun.rb      - Uncomment and add your Raygun API key if need be
│   └── newrelic.yml       -
├── db                     -
│   ├── migrate            - See "bundle exec rake --tasks" (use 'g:migration')
│   │   └── .gitkeep       -
│   ├── schema.rb          - Same as the equivalent file in Rails
│   └── seeds.rb           - Same as the equivalent file in Rails
├── log                    -
│   └── .gitkeep           - By default, log files are written here, as in Rails
```

If you're using Active Record to store data, you should read about the recommended approach for resource implementation code via the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html).

#### The startup process

Now we get into the more interesting bits! The shell is quite small so it is easy to read all of the code to understand exactly what everything is doing and completely demystify your entire code base. We really, really strongly recommend you do that.

```
├── config.ru      - The starting point. This is what `rackup` reads.
├── environment.rb - The first thing that `config.ru` loads.
```

* When you issue a command such as `rackup`, Rack loads `config.ru`
* `config.ru` first loads `environment.rb`, which:
  * Reads `RACK_ENV`
  * Requires Bundler and asks Bundler to require all the Gemfile entries
  * Sets up configuration object `Service.config...`, so that you can read and write to arbitrary global `Service.config.foo` values from anywhere
  * Sets up `Service.config.root` as the service's root folder path and `Service.config.env` as the Hoodoo-derived environment, which matches `RACK_ENV` but adds query methods; e.g. you can write code such as, `if Service.config.env.production?`
  * Tells Hoodoo where the `log` folder is
  * Wakes up Active Record if Active Record is present, telling it about `config/database.yml`. You can optionally set environment variable `DATABASE_URL` and it'll establish a connection to that instead, ignoring `database.yml`, but that'll only work if the URL contains everything needed to connect to the correct database as the correct database user
  * Loads the environment-specific configuration file if it exists
  * Loads files in `config/initializers` _in alphabetical order_
  * Loads files in `service/models` (see later) _in alphabetical order_
  * Loads files in `service/resources` (see later) _in alphabetical order_
  * Loads files in `service/implementations` (see later) _in alphabetical order_
  * Loads files in `service/interfaces` (see later) _in alphabetical order_
* `config.ru` then tells Rack to use NewRelic monitoring, if present
* It then tells Rack to use the Hoodoo framework
* It then loads file `service.rb` in the service root folder, which _must define a class called `ServiceApplication`_ that is a subclass of `Hoodoo::Services::Service`. This class is instantiated and passed to Rack as the runnable application. Rack runs this with whatever web server it has been told to use, or uses by default.

You can add other folders to the loaders at the end of `environment.rb` by copying the pattern of lines already there. You might, for example, add in automatic loading of any files in a `lib` folder you create.

See the `README.md` file for a list of commands you can use to start up the service.

#### The actual service code

Filenames given here are useful conventions but not mandatory. You can call files anything you want and split the classes up any way and anywhere you want within the folders that `environment.rb` automatically includes (see above), but it's generally a good idea to stick to the conventions for clarity. Only the `service.rb` file must be kept as described above, defining a class `ServiceApplication` that's a descendant of `Hoodoo::Services::Service`, because `config.ru` relies upon it.

For each resource endpoint you want to create you should do the following. Suppose the resource was called `Account``:

* Create a file for the implementation class, containing a subclass of `Hoodoo::Services::Implementation` called `AccountImplementation`, in `service/implementations/account_implementation.rb`.
* Create a file for the interface class, containing a subclass of `Hoodoo::Services::Interface` called `AccountInterface`, in `service/implementations/account_interface.rb`.
* Create a representation of the API resource which represents an Account in `service/resources/account_resource.rb`, probably namespaced; see the [Presenters Guide]({{ site.baseurl }}/guides_0400_presenters.html) for details and the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html) for a worked example.
* If the resource Account has one or more Active Record (or other ORM) models that support it, create file(s) for these inside `service/models`. There's no requirement to have anything in common between resource names and persistence layer names; they're entirely decoupled, connected only by the way in which you write your implementation code; but often one resource has one associated model of a similar name, so you'd probably end up writing a file `service/models/account_model.rb` containing a class called `Account`, subclassing either `Active Record::Base` or `Hoodoo::ActiveRecord::Base` if you wanted to include all Hoodoo mixins -- see the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html) for details.
* Edit `service.rb` so that it has a `comprised_of` line that includes the new interface class you defined -- e.g. `comprised_of AccountInterface`.

```
├── service
│   ├── implementations    - Conventional location of implementation classes
│   │   └── .gitkeep
│   ├── interfaces         - Conventional location of interface classes
│   │   └── .gitkeep
│   ├── models             - Conventional location of Active Record models
│   │   └── .gitkeep
│   └── resources          - Conventional location of resource classes
│       └── .gitkeep
│
├── service.rb             - Update `comprised_of` with new Interfaces
```

#### Testing

Testing is done via [RSpec](http://rspec.info) with a coverage report produced by RCov [RCov](https://github.com/relevance/rcov) which can be read by opening `coverage/rcov/index.html` in your preferred web browser.

> **Important:** When writing tests, note that global RSpec monkey patching is _disabled_ so you'll need to call `RSpec.describe`, rather than just `describe`, to describe tests.

Given the above, a minimal test file looks something like this:

```
require 'spec_helper.rb'

RSpec.describe 'foo' do
  # "it", "before", "context", etc. blocks
end
```

The folder structure for the service's test suite is:

```
└── spec
    ├── factories                  - Use of this is optional, via FactoryGirl;
    │   └── .gitkeep                 contents are included by 'spec_helper.rb'
    ├── generators                 - Shell's own generator tests; self-checks;
    │   └── *.rb                     you can keep or delete at your discretion
    ├── service
    │   ├── implementations        - Rare tests for implementation class code
    │   │   └── .gitkeep
    │   ├── integration            - 'get', 'post', etc. DSL-based API testing
    │   │   ├── .gitkeep
    │   │   └── example_spec.rb    - Read the contents, then delete this file
    │   ├── interfaces             - Extremely rare tests for interface code
    │   │   └── .gitkeep
    │   ├── models                 - Tests of model logic, if any is present
    │   │   └── .gitkeep
    │   └── resources              - Tests to verify resource schema
    │       └── .gitkeep
    ├── spec_helper.rb             - Sets everything up for RSpec
    └── support                    - Contents are included by 'spec_helper.rb'
        ├── app_for_integration.rb - Read the comments in these files to
        ├── database_cleaner.rb      understand how each one helps you with
        ├── factory_girl.rb          tests or what changes you might need to
        └── rack_test.rb             make.
```

##### Modifying the coverage report

Underneath the test coverage report from RCov is [SimpleCov](https://github.com/colszowka/simplecov). By default the RCov formatter is used because its output is lighter weight -- faster in a web browser and the lack of syntax highlighting makes "red" untested lines in source code stand out far better -- but it doesn't fully support groups. You might want those, or want the syntax highlighting of the SimpleCov formatter. To achieve this, remove the line that says `SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter` in `spec_helper.rb`. Note that your coverage reports will now be found one level up, in `coverage/index.html`, rather than down in `coverage/rcov/index.html`.

##### Further reading

For more information on writing service tests, recommended practices and advanced techniques, please see the [Testing Guide]({{ site.baseurl }}/guides_0900_testing.html).



## Next Steps

* Although you may well be itching to dive in and write some prototype service code, it is _extremely_ strongly recommended that you understand the Hoodoo security model before you write anything. See the [Security Guide]({{ site.baseurl }}/guides_0200_security.html).

* Once you're at the point of writing resource implementations, then if you're using Active Record to store data, you should read about the recommended approach via the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html).

* When you want to start returning information from your API call implementations, you should really do it through the Hoodoo presenter layer. See the [Presenters Guide]({{ site.baseurl }}/guides_0400_presenters.html) for help and the [Active Record Guide]({{ site.baseurl }}/guides_0300_active_record.html) for a worked example.

* For an easy way to call your real, served-up APIs from other Ruby code, see the the [Hoodoo::Client Guide]({{ site.baseurl }}/guides_0800_hoodoo_client.html).
