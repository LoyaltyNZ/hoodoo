---
layout: default
categories: [guide]
title: Major version upgrades
---

## Overview

From time to time, Hoodoo changes its major version number, signalling backwards-incompatible changes in either its API, or the API of dependencies which mean service authors may need to update their code.

This Guide cannot cover all possible changes that might arise from third party code but does its best to describe the known alterations that authors will need to make.



## Hoodoo v1 to v2

This Hoodoo bump also includes:

* [Airbrake](https://github.com/airbrake/airbrake) v4 to v7, causing changes in configuration and Hoodoo internals
* [Raygun](https://github.com/MindscapeHQ/raygun4ruby) v1 to v2, which introduces no API changes but the alterations for Airbrake lead to an improved initialiser pattern you should consider adopting
* [ActiveSupport](https://github.com/rails/rails/tree/master/activesupport) / [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord) v4 to v5, causing changes for migrations and deletion
* FactoryGirl has been renamed to [FactoryBot](https://github.com/thoughtbot/factory_bot)
* Fixes for frozen objects



### Airbrake v4 to v7

Airbrake v5 upwards require changes in configuration to get things working. Since Airbrake also appears to insert itself into the Rack request chain without being asked in its newest incarnation, alterations in the environment-based exclusion code are needed too.

For detailed information see the [Airbrake v4 to v5 migration guide](https://github.com/airbrake/airbrake/blob/master/docs/Migration_guide_from_v4_to_v5.md). There doesn't seem to be an equivalent for v5-6 or v6-7, hopefully because no breaking API changes were introduced.

#### Before

```ruby
require 'airbrake'

Airbrake.configure do | config |
  config.api_key = 'YOUR_AIRBRAKE_API_KEY'
end

Hoodoo::Services::Middleware::ExceptionReporting.add(
  Hoodoo::Services::Middleware::ExceptionReporting::AirbrakeReporter
) unless Service.config.env.test? || Service.config.env.development?
```

#### After

```ruby
unless Service.config.env.test? || Service.config.env.development?

  require 'airbrake'

  Airbrake.configure do | config |
    config.project_id  = 'YOUR_AIRBRAKE_PROJECT_ID'
    config.project_key = 'YOUR_AIRBRAKE_PROJECT_KEY'

    config.app_version = File.read( File.expand_path( '../../../VERSION', __FILE__ ) ).strip
    config.environment = Service.config.env
  end

  Hoodoo::Services::Middleware::ExceptionReporting.add(
    Hoodoo::Services::Middleware::ExceptionReporting::AirbrakeReporter
  )

end
```



### Raygun v1 to v2

Most people should encounter no _required_ changes here but it's worthwhile adopting the pattern described above for the Airbrake initialiser to ensure that Raygun is completely inactive in environments where it is not wanted, both in current and future versions.

#### Before

```ruby
require 'raygun4ruby'

Raygun.setup do | config |
  config.api_key = 'YOUR_RAYGUN_API_KEY'
end

Hoodoo::Services::Middleware::ExceptionReporting.add(
  Hoodoo::Services::Middleware::ExceptionReporting::RaygunReporter
) unless Service.config.env.test? || Service.config.env.development?
```

#### After

```ruby
unless Service.config.env.test? || Service.config.env.development?

  require 'raygun4ruby'

  Raygun.setup do | config |
    config.api_key = 'YOUR_RAYGUN_API_KEY'
  end

  Hoodoo::Services::Middleware::ExceptionReporting.add(
    Hoodoo::Services::Middleware::ExceptionReporting::RaygunReporter
  )

end
```



### Datadog 0.10.x to 0.11.x or later

If you're using Datadog, a bundle update for this minor version change introduces a completely new syntax for initialisation. This is a little surprising but the new approach is quite a lot cleaner. Full details are at [http://gems.datadoghq.com/trace/docs/](http://gems.datadoghq.com/trace/docs/).

For the out-of-box Hoodoo service shell configuration, the following changes are needed to both the Datadog initializer Ruby file and `config.ru`.

#### Before

In `config/initializers/datadog.rb`:

```ruby
require 'ddtrace/contrib/rack/middlewares'

Datadog::Monkey.patch_module( :active_record )

tracer = Datadog.tracer

tracer.configure(
  :enabled   => ! [ 'test','development' ].include?( ENV[ 'RACK_ENV' ] ),
  :hostname  => ENV[ 'DD_AGENT_PORT_8126_TCP_ADDR' ],
  :port      => ENV[ 'DD_AGENT_PORT_8126_TCP_PORT' ]
)

Service.config.com_datadoghq_datadog_tracer = tracer
```

In `config.ru`, you may have had something like this, including a mention of your service's name:

```ruby
# Datadog automatic Rack monitoring.
#
# https://datadoghq.com
# https://github.com/DataDog/ddtrace-rb
#
require 'ddtrace/contrib/rack/middlewares'

use Datadog::Contrib::Rack::TraceMiddleware, {
    tracer: Service.config.com_datadoghq_datadog_tracer,
    default_service: 'your_service_name'
}
```

#### After

Inside `config/initializers/datadog.rb`, everything is configured in a single block and the service's name moves from `config.ru` into this file:

```ruby
# For more information see:
#
# * http://gems.datadoghq.com/trace/docs/
# * https://github.com/DataDog/docker-dd-agent
#
require 'ddtrace'

Datadog.configure do | c |

  # Datadog tracing is only enabled in non-test/non-development environments.
  #
  c.tracer enabled:  [ 'test', 'development' ].exclude?( ENV[ 'RACK_ENV' ] ),
           hostname: ENV[ 'DD_AGENT_PORT_8126_TCP_ADDR' ],
           port:     ENV[ 'DD_AGENT_PORT_8126_TCP_PORT' ]

  c.use :rack, distributed_tracing: true,
               service_name:        'your_service_name'

  # Examples below are optional. If you use Net/HTTP to call out to external
  # services, or for inter-resource calls on a non-AMQP deployment, keep the
  # ":http" middleware; likewise ":active_record" if you use that for
  # persistent storage. The ":dalli" middleware is for Memcached, typically
  # used as a session store. These and other integrations are described at:
  #
  #   http://gems.datadoghq.com/trace/docs/#Available_Integrations
  #
  c.use :http, distributed_tracing: true
  c.use :active_record
  c.use :dalli

end

```

Inside `config.ru`, things get much simpler:

```ruby
# Enable DataDog monitoring.
#
use Datadog::Contrib::Rack::TraceMiddleware
```



### ActiveRecord v4 to v5

There are a number of changes you should make here.

#### Migrations

Migrations now need to inherit from a class name indicating the ActiveRecord version to which that migration applies. A simple service-wide search and replace can achieve this:

* `< ActiveRecord::Migration` to `< ActiveRecord::Migration[4.2]`

You'll need to adjust the above if your preferred use of white space means that the search string wouldn't find all migration instances in your source code. The arising syntax may look a little strange but is valid; the change is as simple as the above indicates. For example:

```ruby
class CreatePurchases < ActiveRecord::Migration
  def up
    # ...
  end

  #...
end
```

...only needs its `class` declaration updating, so it just becomes:

```ruby
class CreatePurchases < ActiveRecord::Migration[4.2]
  def up
    # ...
  end

  #...
end
```

Using `RACK_ENV=test be rake db:drop db:create db:migrate` is a good way to re-test your entire migration history on a local test mode database, leaving other development data unaltered.

#### Arrays

If you use arrays and have validations around their type or contents then beware improvements in ActiveRecord's array handling and typecasting that may mean classes and array contents are not quite what you expect. Generally the behaviour is an improvement but be sure you have good test coverage around array column data.

#### Deprecations

ActiveRecord 5.0 introduced a lot of deprecations and a relatively short time later ActiveRecord 5.1 removed a lot of those previously deprecated features. For example, it no longer supports this form of deletion:

```ruby
Model.delete_all( { some: conditions } )
```

Instead, use `where`:

```ruby
Model.where( { some: conditions } ).delete_all()
```

Validation conditions of `:if` and `:unless` used to take String arguments, with an implied use of `eval` in the implementation; these now been deprecated, so use lambdas instead; e.g. move from:

```ruby
validate :some_custom_validation_method, unless: "some_field.blank?"
```

...to:

```ruby
validate :some_custom_validation_method, unless: -> { some_field.blank? }
```

For other deprecations and removals, see the guides listed in the section below.

#### Other issues

The change list of ActiveRecord is too large to cover here, so in addition to the above, depending on your confidence in your test coverage, you may want to look at:

* [Rails 5.0 release notes - ActiveRecord changes](http://guides.rubyonrails.org/5_0_release_notes.html#active-record)
* [Rails 5.1 release notes - ActiveRecord changes](http://guides.rubyonrails.org/5_1_release_notes.html#active-record)



### FactoryGirl to FactoryBot

If you use the FactoryGirl gem, note that this has changed name to FactoryBot. It is a rename without API changes, so it should be sufficient to do a service-wide search and replace:

* `factory_girl` to `factory_bot`
* `FactoryGirl` to `FactoryBot`

...and update your Gemfile with `gem 'factory_bot', '~> 4.8'` in place of its `factory_girl` entry.



### Fixes for frozen objects

Hoodoo used to recommend a particular pattern for estimated counts which involved changing a string using `gsub!`. In newer Ruby versions or services this string can be frozen by default, so the pattern has been updated.

At the time of writing, this is the only case known of where Hoodoo itself recommended a bad pattern and callers should update their code. Within your own code base, though, there's always a chance you might trip over other problems with external gems and frozen objects. Hoodoo had to work around a similar issue within Airbrake (though this is hopefully fixed by the time you read this Guide); if you use Hoodoo's exception reporting abstractions you'll be isolated from the problem anyway, but if you drive Airbrake directly then the v4 to v7 update may introduce problems with Airbrake attempting to modify frozen objects.

As ever, the best defense is to have excellent test coverage.

#### Before

```ruby
FAST_COUNT_ESTIMATOR = Proc.new do | sql |
  begin
    sql.gsub!( "'", "''" ) # Escape SQL for insertion below
    ActiveRecord::Base.connection.execute(
      "SELECT estimated_count('#{ sql }')"
    ).first[ 'estimated_count' ].to_i
  rescue => e
    nil
  end
end
```

#### After

```ruby
FAST_COUNT_ESTIMATOR = Proc.new do | sql |
  begin
    escaped_sql = sql.gsub( "'", "''" )
    ActiveRecord::Base.connection.execute(
      "SELECT estimated_count('#{ escaped_sql }')"
    ).first[ 'estimated_count' ].to_i
  rescue => e
    nil
  end
end
```



### Final changes

Note the updates in the service shell from the last version supporting Hoodoo 1 to the at-time-of-writing version for Hoodoo 2. You should check through the diff and apply any changes you feel are relevant and valuable within your own service:

* [Service shell changes on GitHub](https://github.com/LoyaltyNZ/service_shell/compare/fbb1d4f4c3eebfc627fca6153b9b5deeddb8e41a...9100ec0af9c2d5cbe2969390fb0aad5da6d3a81e)

**In particular note the `Gemfile` and `Rakefile` updates**. Most of the rest of the changes will probably have been covered above already, but note that the migration generator ought to update for ActiveRecord 5.1 not 4.2 - previous steps may have done a search-and-replace that left it at 4.2 for all future migrations. Around line 76, check for:

```ruby
      file.write <<-EOF.strip_heredoc
        class #{migration_class} < ActiveRecord::Migration
        ...
      EOF
```

...which might say `ActiveRecord::Migration[4.2]`; in any case, update it to:

```ruby
      file.write <<-EOF.strip_heredoc
        class #{migration_class} < ActiveRecord::Migration[5.1]
        ...
      EOF
```
