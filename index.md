---
layout: default
categories: [home]
title: Home
---

## What is Hoodoo?

### The Hoodoo Gem

<img class="diagram" src="{{ site.baseurl }}/diagrams/stack.svg">

Hoodoo is a [Ruby](https://www.ruby-lang.org/) [Gem](https://www.ruby-lang.org/en/libraries/) developed by [Loyalty New Zealand](https://www.loyalty.co.nz) that works with [Rack](https://rack.github.io) to provide a framework for creating highly consistent [RESTful](https://www.wikipedia.org/wiki/Representational_state_transfer), [CRUD](https://www.wikipedia.org/wiki/Create,_read,_update_and_delete) APIs with minimal code. It differs from frameworks such as [Rails](http://rubyonrails.org) or [Sinatra](http://www.sinatrarb.com) by being entirely focused on APIs and differs from frameworks such as [Grape](https://intridea.github.io/grape/) by enforcing strict conventions to minimise API inconsistencies.

Hoodoo's code has 100% coverage via [RDoc](http://rdoc.rubyforge.org) and 100% non-trivial automated test coverage via [RSpec](http://rspec.info) according to [RCov](https://github.com/relevance/rcov). Out-of-the-box logging support includes I/O stream, file and [LogEntries](https://logentries.com/) writers, and exception reporters include [Raygun](https://raygun.io) and [Airbrake](https://airbrake.io). It's easy to write new log and exception sinks if you need them.

Hoodoo services can run under any Rack-compliant web server but for truly decoupled, scalable and highly available deployments, use [Alchemy](https://github.com/LoyaltyNZ/alchemy-amq/).

### The Hoodoo API Specification

The [Hoodoo API Specification]({{ site.custom.api_specification_url }}) describes the conventions that Hoodoo enforces. In many respects, this specification is to Hoodoo as the [Rack Interface Specification](http://www.rubydoc.info/github/rack/rack/master/file/SPEC) is to Rack. API endpoint authors **require** a reasonable understanding of the Specification so they know what is expected of their services.



## Minimal example

This is a very brief example showing you how to install some required gems and get a Resource endpoint up and running all in a single Ruby file. The code is pulled apart and explained in detail in the [Fundamentals Guide]({{ site.baseurl }}/guides_0100_fundamentals.html), which also includes other more useful examples.

### Install gems

Install Thin, Rack and Hoodoo:

```sh
gem install thin
gem install rack
gem install hoodoo
```

### The service code

```ruby
require 'rack'
require 'hoodoo'

class TimeImplementation < Hoodoo::Services::Implementation
  def show( context )
    context.response.set_resource( { 'time' => Time.now.utc.iso8601 } )
  end
end

class TimeInterface < Hoodoo::Services::Interface
  interface :Time do
    endpoint :time, TimeImplementation
    public_actions :show
  end
end

class TimeService < Hoodoo::Services::Service
  comprised_of TimeInterface
end

# This is a hack for the example and needed if you have Active Record present,
# else Hoodoo will expect a database connection.
#
Object.send( :remove_const, :ActiveRecord ) rescue nil

builder = Rack::Builder.new do
  use( Hoodoo::Services::Middleware )
  run( TimeService.new )
end

Rack::Handler::Thin.run( builder, :Port => 9292 )
```

### Start the service

```sh
ruby <filename.rb>
```

### Make an API call

Now you can talk to it with, say, [cURL](http://curl.haxx.se). Note that Hoodoo _requires_ the `Content-Type` header as shown:

```sh
curl http://127.0.0.1:9292/v1/time/now --header 'Content-Type: application/json; charset=utf-8'
# => {"time":"2015-08-03T02:31:34Z"}
```

Other frequently used test clients are the [Postman](https://www.getpostman.com) extension for [Google Chrome](https://chrome.google.com), [Paw](https://luckymarmot.com/paw) on Mac OS X, or use Ruby and <code>Hoodoo::Client</code>, described in the [Hoodoo::Client Guide]({{ site.baseurl }}/guides_0800_hoodoo_client.html).