# Hoodoo v3.x

## 3.5.8

Automated Monthly Patching Jun24
- Gems updated:
  - bigdecimal 3.1.8 (was 3.1.7) with native extensions
  - timecop 0.9.9 (was 0.9.8)
  - i18n 1.14.5 (was 1.14.4)
  - rexml 3.2.8 (was 3.2.6)
  - activesupport 7.0.8.3 (was 7.0.8.1)
  - activemodel 7.0.8.3 (was 7.0.8.1)
  - activerecord 7.0.8.3 (was 7.0.8.1)

## 3.5.7

Automated Monthly Patching May24
- Gems updated:
  - public_suffix 5.0.5 (was 5.0.4)

## 3.5.6

Automated Monthly Patching Mar24
- Gems updated:
  - bigdecimal 3.1.7 (was 3.1.6) with native extensions
  - rack 2.2.9 (was 2.2.8.1)
  - i18n 1.14.4 (was 1.14.1)
  - rdoc 6.5.1.1 (was 6.5.0)

## 3.5.5

- Removed the `Hoodoo::Services::Middleware::Middleware#has_memcached? is deprecated - use #has_session_store?` deprecation warning. The `has_memcached?` method is still in use within the library and only once that has been resolved, will the deprecation warning can be re-introduced.
- Updated rdoc gem to fix security vulnerabilities.

## 3.5.4

Automated Monthly Patching Mar24
- Gems updated:
  - bigdecimal 3.1.6 (was 3.1.5) with native extensions
  - rack 2.2.8.1 (was 2.2.8)
  - dalli 3.2.8 (was 3.2.7)
  - diff-lcs 1.5.1 (was 1.5.0)
  - drb 2.2.1 (was 2.2.0)
  - pg 1.5.6 (was 1.5.4) with native extensions
  - rspec-support 3.12.2 (was 3.12.1)
  - rspec-core 3.12.3 (was 3.12.2)
  - rspec-expectations 3.12.4 (was 3.12.3)
  - rspec-mocks 3.12.7 (was 3.12.6)
  - activesupport 7.0.8.1 (was 7.0.8)
  - activemodel 7.0.8.1 (was 7.0.8)
  - activerecord 7.0.8.1 (was 7.0.8)
  - crack 0.4.6 (was 0.4.5)

## 3.5.3

- Updated ruby to 3.3.0

## 3.5.2

Automated Monthly Patching Feb24
- Gems updated:
  - diff-lcs 1.5.1 (was 1.5.0)
  - rspec-support 3.12.2 (was 3.12.1)
  - rspec-core 3.12.3 (was 3.12.2)
  - rspec-expectations 3.12.4 (was 3.12.3)
  - rspec-mocks 3.12.7 (was 3.12.6)

## 3.5.1

Automated Monthly Patching Jan24
- Gems updated:
  - concurrent-ruby 1.2.3 (was 1.2.2)
  - dalli 3.2.7 (was 3.2.6)
  - simplecov-rcov 0.3.7 (was 0.3.3)

## 3.5.0

- Updated `Caller` resource schema, added `authentication_secret_parameter_store_path` - [FT-4004](https://loyaltynz.atlassian.net/browse/FT-4004)

## 3.4.3

Automated Monthly Patching Jan24
- Gems updated:
  - addressable 2.8.6 (was 2.8.5)
  - psych 5.1.2 (was 5.1.1.1) with native extensions

## 3.4.2

Automated Monthly Patching Dec23
- Gems updated:
  - public_suffix 5.0.4 (was 5.0.3)
  - stringio 3.0.9 (was 3.0.8) with native extensions

## 3.4.1

Automated Monthly Patching Nov23
- Gems updated:
  - ffi 1.16.3 (was 1.16.2) with native extensions
  - psych 5.1.1.1 (was 5.1.0) with native extensions
  - irb 1.8.3 (was 1.8.1)

## 3.4.0

- Requires ddtrace gem 1.0 or better [DS-3791](https://loyaltynz.atlassian.net/browse/DS-3791)
  - Applications will need to update their Gems to match, see the [Upgrade guide](https://github.com/DataDog/dd-trace-rb/blob/master/docs/UpgradeGuide.md#1.0-configuration-requires) for help.
- Added support for debugging specs from inside VSCode.

## 3.3.3

Automated Monthly Patching Oct23
- Gems updated:
  - dalli 3.2.6 (was 3.2.5)
  - timecop 0.9.8 (was 0.9.6)
  - activesupport 7.0.8 (was 7.0.6)
  - simplecov-rcov 0.3.3 (was 0.3.1)
  - activemodel 7.0.8 (was 7.0.6)
  - activerecord 7.0.8 (was 7.0.6)

## 3.3.2

Automated Monthly Patching Aug23
- Gems updated:
  - rack 2.2.8 (was 2.2.7)
  - rexml 3.2.6 (was 3.2.5)
  - addressable 2.8.5 (was 2.8.4)
  - rspec-mocks 3.12.6 (was 3.12.5)

## 3.3.1

- Support ruby `3.1.2` - [DS-3525](https://loyaltynz.atlassian.net/browse/DS-3525)

## 3.3.0

- Replace gem `le` with `r7insight` - [DS-3525](https://loyaltynz.atlassian.net/browse/DS-3525)
  - Callers must include  the `r7insight` gem instead of `le` gem in their `Gemfile`

## 3.2.9

- Update ruby-version to `3.2.2` [FT-3182](https://loyaltynz.atlassian.net/browse/FT-3182)

## 3.2.8

Automated Monthly Patching Jul23
- Gems updated:
  - rspec-support 3.12.1 (was 3.12.0)
  - activesupport 7.0.6 (was 7.0.5)
  - activemodel 7.0.6 (was 7.0.5)
  - activerecord 7.0.6 (was 7.0.5)

## 3.2.7

Automated Monthly Patching Jun23
- Gems updated:
  - thor 1.2.2 (was 1.2.1)
  - activesupport 7.0.5 (was 7.0.4.3)
  - activemodel 7.0.5 (was 7.0.4.3)
  - activerecord 7.0.5 (was 7.0.4.3)

## 3.2.6

Automated Monthly Patching May23
- Gems updated:
  - rack 2.2.7 (was 2.2.6.4)
  - addressable 2.8.4 (was 2.8.3)
  - rspec-core 3.12.2 (was 3.12.1)
  - rspec-expectations 3.12.3 (was 3.12.2)

## 3.2.5

Automated Monthly Patching Apr23
- Gems updated:
  - addressable 2.8.3 (was 2.8.2)

## 3.2.4

Automated Monthly Patching Apr23
- Gems updated:
  - addressable 2.8.2 (was 2.8.1)
  - rspec-mocks 3.12.5 (was 3.12.4)

## 3.2.3

Automated Monthly Patching Mar23
- Gems updated:
  - rack 2.2.6.4 (was 2.2.6.2)
  - pg 1.4.6 (was 1.4.5) with native extensions
  - rspec-mocks 3.12.4 (was 3.12.3)
  - activesupport 7.0.4.3 (was 7.0.4.2)
  - activemodel 7.0.4.3 (was 7.0.4.2)
  - activerecord 7.0.4.3 (was 7.0.4.2)

## 3.2.2

Automated Monthly Patching Feb23
- Gems updated:
  - dalli 3.2.4 (was 3.2.3)
  - redis 4.8.1 (was 4.8.0)
  - rspec-core 3.12.1 (was 3.12.0)
  - tzinfo 2.0.6 (was 2.0.5)
  - activesupport 7.0.4.2 (was 7.0.4.1)
  - activemodel 7.0.4.2 (was 7.0.4.1)
  - activerecord 7.0.4.2 (was 7.0.4.1)

## 3.2.1 (2023-01-19)

- Monthly patches. [DS-2849](https://loyaltynz.atlassian.net/browse/DS-2849)

## 3.2.0 (2023-01-09)

- Updated `dalli` gem requirements to disallow 2.7.x. [DS-2723](https://loyaltynz.atlassian.net/browse/DS-2723)

## 3.1.7 (2022-11-22)

- Updated `dalli` from 2.x to 3.x, to fix security vulnerabilities. [DS-2779](https://loyaltynz.atlassian.net/browse/DS-2779)

## 3.1.6 (2022-10-04)

- Updated docs for 'downstream_error' added in v3.1.5 [FT-1114](https://loyaltynz.atlassian.net/browse/FT-1114)

## 3.1.5 (2022-09-29)

- Add 'downstream_error' to error_descriptions [FT-1114](https://loyaltynz.atlassian.net/browse/FT-1114)

## 3.1.4 (2022-08-02)

- Fix rdoc generation. Removed refences to sdoc gem which has security vulnerabilities. [FT-1253](https://loyaltynz.atlassian.net/browse/FT-1253)
- Updated `rack` and `activerecord` gems to fix security vulnerabilities.

## 3.1.3 (2022-04-27)

- Introduces guideline steps about how-to deploy a `Hoodoo` release to Rubygems [DS-2034](https://loyaltynz.atlassian.net/browse/DS-2034)

## 3.1.2 (2022-04-26)

- Testing `Hoodoo` release [DS-2034](https://loyaltynz.atlassian.net/browse/DS-2034)

## 3.1.1 (2022-04-19)

- Tagging `Hoodoo` [DS-2034](https://loyaltynz.atlassian.net/browse/DS-2034)

## 3.1.0 (2022-04-07)

- Update ruby-version to 3.1.0 [DS-2034](https://loyaltynz.atlassian.net/browse/DS-2034)
- Update `Bundler` to 2.3.10
- Update `Rspec` to 3.11
- Update other general gems in patch level

## 3.0.1 (2022-02-16)

- Fixed travis false positive build and broken specs [DS-1930](https://loyaltynz.atlassian.net/browse/DS-1930)

## 3.0.0 (2022-02-01)

- Update ruby-version to 2.7.3
- Update `activerecord` [DS-1484](https://loyaltynz.atlassian.net/browse/DS-1484)
- Removes support for ruby versions < 2.7.3

# Hoodoo v2.x

## 2.12.11 (2021-11-30)

- Update `Postgres` to version 13.3 [FT-811](https://loyaltynz.atlassian.net/browse/FT-811)

## 2.12.10 (2021-09-20)

- Fix travis release to limit publishing build to a single `ruby` version.

## 2.12.9 (2021-09-07)

- Add HTTP Header [X-Disable-Downstream-Sync](./docs/api_specification#http_x_disable_downstream_sync)

## 2.12.8 (2021-05-31)

- bundle update to fix security vulnerability [CVE-2021-31799](https://www.ruby-lang.org/en/news/2021/05/02/os-command-injection-in-rdoc/)
- Set $SAFE = 0 to disable taint tracking and keep the behaviour consistent between older ruby versions & 2.7+

## 2.12.7 (2021-02-12)

- If an exception occurs while logging a message, pretty print the object that caused the error to stderr, so that callers have more context for troubleshooting.
- Maintenance Travis migrated to use travis-ci.com
- bundle update `activerecord` to fix security vulnerability `CVE-2021-22880`.

## 2.12.6 (2020-11-10)

- Update examples for encoding search value
- Bundle audit update and fixed broken specs after rack update
- Remove ruby 2.2 from support matrix

## 2.12.5 (2020-01-10)

- Increase logged payload size in the `Middleware` to ensure payload data is not lost from the logs.
- Maintenance bundle update

## 2.12.4 (2019-11-15)

- Add `updated_at` to common resource schema fields.

## 2.12.3 (2019-11-12)

- Bug fix, removed dependency on the Rails `blank?` method.

## 2.12.2 (2019-07-11)

- Support `hash` as a valid property type for keys.

## 2.12.1 (2019-02-22)

- Disallows calls to `show` with `nil` identifiers. Previously these got interpreted as `list` calls; now they return `404 Not Found`.

## 2.12.0 (2018-12-17)

- Extends [Session](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Session.html) storage functionality to allow use of any supported [TransientStore](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/TransientStore.html) storage engine. Previously, Hoodoo only supported session storage through `memcached`.

  - For code driving the session engine directly, this release deprecates the specific `memcached` options key `:memcached_host` in [Hoodoo::Services::Session#initialize](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Session.html#method-c-new) and replaces it with more technology agnostic options keys `:storage_host_uri` and `:storage_engine`.

  - In the middleware, session storage details can be set by services via new environment variables `SESSION_STORE_ENGINE` and `SESSION_STORE_URI`. See the RDoc documentation for new class methods [`#session_store_engine`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Middleware.html#method-c-session_store_engine) and [`#session_store_uri`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Middleware.html#method-c-session_store_uri) for details; this pair of methods replaces the now-deprecated [`#memcached_host`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Middleware.html#method-c-memcached_host), though this continues to be supported for backwards compatibility.

    For example, this configures a Redis engine:

    ```ruby
    ENV[ 'SESSION_STORE_ENGINE' ] = 'redis'
    ENV[ 'SESSION_STORE_URI'    ] = 'https://example.com:4567'
    ```

    ...while this configures a mirrored Redis and Memcached strategy:

    ```ruby
    ENV[ 'SESSION_STORE_ENGINE' ] = 'redis_memcached_mirror'
    ENV[ 'SESSION_STORE_URI'    ] = "{\"memcached\": \"localhost:11211\", \"redis\": \"redis://localhost:6379\"}"
    ```

  - New enquiry class method [`#has_session_store?`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Middleware.html#method-c-has_session_store-3F) replaces now-deprecated [`#has_memcached?`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Middleware.html#method-c-has_memcached-3F), though this also continues to be supported for backwards compatibility.

  - Memcached is used by default when the new environment variables are unset, making this a non-breaking change via fallback to old behaviour.

## 2.11.1 (2018-12-12)

- Hoodoo v2.0.0's release back in 2017 included a requirement to use Rack 2 or later. While this is important for security reasons on anything using the Hoodoo middleware, it does meant that software using just the _client_ or other non-middleware gem components is forced to use Rack 2 as well. This constraint has been relaxed, though _caveat emptor_; if writing a service, it'll be up to you to ensure Rack 2 is present.

## 2.11.0 (2018-12-12)

- Moved the [Hoodoo::ActiveRecord::ErrorMapping](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/ErrorMapping.html) mixin core mapping code out to support method [Hoodoo::ActiveRecord::Support#translate_errors_on](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Support.html#method-c-translate_errors_on) so that it can be called for arbitrary ActiveRecord model instances, whether or not they use the Hoodoo error mapping mixin.

## 2.10.0 (2018-12-04)

- Allows [Hoodoo::Utilities.is_in_future?](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Utilities.html#method-c-is_in_future-3F) to compare a timestamp against a timestamp other than `DateTime.now` (e.g. for backdated context).
- Maintenance `bundle update`.

## 2.9.0 (2018-08-21)

- Support wildcards in [identity maps](https://github.com/LoyaltyNZ/hoodoo/blob/master/docs/api_specification/README.md#caller.resource.interface.identity_maps) - as well as an Array of permitted values, the string `"*"` can be used as a permit-all wildcard. This is obviously as dangerous as it is powerful and should only be used with great caution.

## 2.8.0 (2018-08-07)

- New "feature" of sorts, for [`#new_in`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Creator/ClassMethods.html#method-i-new_in) - it no longer requires manual or automated dating support to be included or enabled. Setting the `created_at` value of a resource can have use cases outside of the need to support historic representations.

## 2.7.0 (2018-08-06)

- General maintenance pass, updating development and runtime dependencies and including `bundle-audit`.

## 2.6.1 (2018-06-01)

- Fix edge case in `enumerate_all` method within [Hoodoo::Client::PaginatedEnumeration](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Client/PaginatedEnumeration.html) which caused bad behaviour should the caller use key `:offset` (Symbol) rather than `"offset"` (String) in a `#list` call's query options Hash.

## 2.6.0 (2018-05-23)

- Add in a security exemption mechanism to the ActiveRecord security layer. The options passed into [Hoodoo::ActiveRecord::Secure::ClassMethods#secure_with](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Secure/ClassMethods.html#method-i-secure_with) now accept an exemptions key described in a subsection under the main [Hoodoo::ActiveRecord::Secure::ClassMethods#secure](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Secure/ClassMethods.html#method-i-secure) method documentation.
- This mechanism allows **with due caution** wildcards and similar to be used in the session layer, which is very useful for superuser-like Caller scopes. Long lists of must-match values would not need to be maintained nor would there be a risk of scalability issues arising from very large SQL queries. A wildcard in the security layer is extremely powerful but equally dangerous, so this is something only to be used after very careful consideration.
- The new security features above are based around Procs which get called with relevant session scoping values and indicate via a boolean value whether or not the data qualifies for an exemption. An example is checking a field from session scope to see if there is a wildcard character present. For convenience, the [Hoodoo::ActiveRecord::Secure](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Secure.html) module defines Object-equals-asterisk and Array-includes-asterisk exemption Procs in constants `OBJECT_EQLS_STAR` and `ENUMERABLE_INCLUDES_STAR` respectively.
- If these are unsuitable, the new [Hoodoo::ActiveRecord::Secure::SecurityHelper](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/hoodoo/docs/rdoc/classes/Hoodoo/ActiveRecord/Finder/SecurityHelper.html) module provides various constructor methods to assist with Proc creation. If none of these are suitable either, please examine the implementation of the methods in order to understand how to write a robust custom Proc by hand.
- New alias of `#update_in` for [Hoodoo::ActiveRecord::Writer::ClassMethods#persist_in](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Writer/ClassMethods.html#method-i-persist_in) (and the [instance equivalent](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Writer.html#method-i-persist_in)). This is syntax sugar. It was added because authors of `#update` methods in resource implementation classes may find this a more natural name to use (and more discoverable in the documentation).
- New alias of `#endpoint` for [Hoodoo::Client#resource](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Client.html#method-i-resource) and the inter-resource call equivalent, [Hoodoo::Services::Context#resource](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Context.html#method-i-resource). This is syntax sugar. It was added becuse callers may prefer to think of the method as providing an object that's basically a proxy for the resource implementation, or an endpoint that lets one talk to the resource implementation. The name of the method used is up to the caller's preference.

## 2.5.1 (2018-05-18)

- The hash in the implementation for v2.5.0 was not directly compatible with passing into a Hoodoo endpoint for things like proxying calls; this made it clumsy, when it was meant to assist. Fixed this, though it does mean anyone already using the code will have to update their implementation.

## 2.5.0 (2018-05-17)

- Added [`Hoodoo::Services::Request::ListParameters#to_h`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Request/ListParameters.html#method-i-to_h) and [`Hoodoo::Servics::Request::ListParameters#from_h!`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Request/ListParameters.html#method-i-from_h-21) to assist various scenarios when dealing with search and filter data in `#list` implementations.

## 2.4.3 (2018-05-10)

- Relaxing alchemy-flux constraint for development and test to use the latest [Alchemy Flux](http://loyaltynz.github.io/alchemy-flux/doc/index.html).
- Maintenance `bundle update` for the latest [Alchemy Flux](http://loyaltynz.github.io/alchemy-flux/doc/index.html).

## 2.4.2 (2018-04-30)

- Maintenance `bundle update`.
- Allow Date instances to be passed to [`Hoodoo::Utilities::rationalise_datetime`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Utilities.html#method-c-rationalise_datetime).

## 2.4.1 (2018-04-13)

- Maintenance `bundle update`.
- Fixes a `Hoodoo::Client` bug with the Errors resource. Any JSON response with `Errors` in `kind` was promoted to an error-like condition internally, but when dealing with an endpoint that actually _implements the Errors resource interface_ then you expect to get such payloads back for non-error conditions. Fixed by simply also checking the HTTP status code in the HTTP-endpoint-like base class underneath the client system. Proof-of-bug (and of fix) tests added.

## 2.4.0 (2018-03-21)

- Add the interaction ID to Datadog tracing [as span `interaction.id`](https://github.com/LoyaltyNZ/hoodoo/pull/248/files#diff-fd75040abee557d577b5765501df2550).
- Maintenance `bundle update`.
- Fix in presenter layer wherein rendering would fail unless `::ActiveRecord::Base` is defined.
- Fix routing expressions to anchor accidental ambiguous routes to start of path (e.g. `/1/Foo/1/Bar` where both resources exist will now correctly route to v1 of `Foo` with `1` and `Bar` treated as URI path components).
- Bump development dependency of PostgreSQL gem `pg` to version 1.x; PostgreSQL 9.2 or later required; see the gem's [change history](https://bitbucket.org/ged/ruby-pg/src/d8734ec382c9af8bd8bbe062d3668c93dd4ecf5b/History.rdoc?at=default&fileviewer=file-view-default) for more information.

## 2.3.0 (2018-02-22)

- Maintenance `bundle update`.
- Introduces environment variable [`HOODOO_CLOCK_DRIFT_TOLERANCE`](http://loyaltynz.github.io/hoodoo/guides_1000_env_vars.html#hoodoo_clock_drift_tolerance) and related method [`Hoodoo::Utilities::is_in_future?`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Utilities.html#method-c-is_in_future-3F).
- Internal caching for a few more environment variables, yielding a small performance improvement.

## 2.2.3 (2018-02-19)

General maintenance update and test matrix support for Ruby 2.5.0. No core function changes, fixes or new features.

## 2.2.2 (2017-11-16)

Fixes long-standing bug in the "decimal" type used in the presenter layer. This previously expected quantities to be presented as BigDecimal objects, but JSON contains no Types that would be converted to such by Ruby; decimals would never validate. Fixed by instead expecting a String with regular expression check; test coverage updated.

Valid decimal strings can have any amount of leading or trailing space, be positive or negative and in simple (e.g. `"-12.45"`) or scientific (e.g. `"-0.1245e2"`) notation.

## 2.2.1 (2017-11-10)

We are very grateful for the fast fix of the Airbrake Ruby frozen Hash modification problems described for Hoodoo v2.2.0 below. Hoodoo's development mode `gemspec` has been updated to require v2.6.0 or later of Airbrake Ruby and the internal Hash duplication workaround has been removed.

- Airbrake Ruby [PR 283](https://github.com/airbrake/airbrake-ruby/pull/283) (now merged)

## 2.2.0 (2017-11-09)

Exception handling abstraction fix - work around Airbrake 6/7 bug which causes it to attempt to modify frozen objects under certain circumstances. See:

- Airbrake Ruby [Issue 281](https://github.com/airbrake/airbrake-ruby/issues/281)
- Airbrake Ruby [PR 283](https://github.com/airbrake/airbrake-ruby/pull/283)

## 2.1.2 (2017-11-07)

The `hoodoo` command option parsing has been overhauled and is now more robust, flexible and easier to maintain in future. Single letter versions of the arguments are available (e.g. `-f` for `--from`) and the `--from` argument is aliased as `--git`/`-g`.

## 2.1.1 (2017-11-03)

No code changes over 2.1.0; minor RDoc fix for estimated counts (avoids mutating possibly frozen string).

## 2.1.0 (2017-11-03)

Introduces a new [generic error](https://github.com/LoyaltyNZ/hoodoo/blob/master/docs/api_specification/README.md#error.common.codes.generic), `generic.contemporary_exists`. Supporting service code can use this either manually, or with assistance methods listed below, to indicate that - in some date-based context - a contemporary ("now") version of some resource instance exists, but it doesn't exist in the context of the date at hand. This is only appropriate if using the [Hoodoo::ActiveRecord::Dated](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Dated.html) or [Hoodoo::ActiveRecord::ManuallyDated](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/ManuallyDated.html) modules, or if implementing a comparable change tracking mechanism independently.

- [Hoodoo::ActiveRecord::Finder::ClassMethods#acquire_in](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-acquire_in) has a new companion interface, [Hoodoo::ActiveRecord::Finder::ClassMethods#acquire_in!](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-acquire_in-21). This is convenient but the trade-off is modification of the passed-in +context+ value. The method adds errors itself; `generic.not_found` for simple cases, along with the new `generic.contemporary_exists` if a dating module exists and the relevant conditions arise.

- [Hoodoo::Services::Response#contemporary_exists](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Response.html#method-i-contemporary_exists) does the same as [Hoodoo::Services::Response#not_found](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Response.html#method-i-not_found) but adds the new `generic.contemporary_exists` error code, for callers who prefer to use [Hoodoo::ActiveRecord::Finder::ClassMethods#acquire_in](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-acquire_in) and manually add appropriate errors.

This pairing and ordering of `generic.not_found` with `generic.contemporary_exists` is recommended in general if adding the new error to existing responses, to reduce the chances of compatibility problems with existing API callers. For new resource implementations, there may be cases where it makes sense to only use `generic.contemporary_exists`.

Supporting new methods are:

- [Hoodoo::ActiveRecord::Finder::ClassMethods#scoped_undated_in](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-scoped_undated_in) is a supporting method that works like [Hoodoo::ActiveRecord::Finder::ClassMethods#scoped_in](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-scoped_in), but specifically omits any dating-aware scope components, leaving just things like security and translation layers in place. Depending on the dating mechanism in use, the caller may then need to manually chain in additional scopes; for example, with [Hoodoo::ActiveRecord::ManuallyDated](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/ManuallyDated.html), an undated scope will address all contemporary _and_ historic records within the single database table it uses for each manually dated ActiveRecord model.

- [Hoodoo::ActiveRecord::Support#add_undated_scope_to](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Support.html#method-c-add_undated_scope_to) is, in essence, to [Hoodoo::ActiveRecord::Support#full_scope_for](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/docs/rdoc/classes/Hoodoo/ActiveRecord/Support.html#method-c-full_scope_for) as `#scoped_undated_in` is to `scoped_in` (see above).

## 2.0.0 (2017-10-13)

- Hoodoo and therefore Hoodoo services now require Ruby 2.2.x or later with Rack v2. Rack v1 and older AMQP support has been removed as it was causing dependency problems with other updated gems that were becoming impractical to resolve, which in turn meant Ruby 2.1.x support was equally impractical.

- Updated to use ActiveSupport 5, ActiveRecord 5, Airbrake 6 and NewRelic 4. These all include API and/or configuration changes that may impact parts of service code outside core Hoodoo changes. See their respective guides and change logs for details:

  - [ActiveSupport 5](http://edgeguides.rubyonrails.org/5_0_release_notes.html#active-support)
  - [ActiveRecord 5](http://edgeguides.rubyonrails.org/5_0_release_notes.html#active-record)
  - [Airbrake 5/6](https://github.com/airbrake/airbrake/blob/master/docs/Migration_guide_from_v4_to_v5.md)
  - [NewRelic 4](https://github.com/newrelic/rpm)

  Headline known changes are:

  - If inheriting from `Hoodoo::ActiveRecord::Base` for Hoodoo extensions in ActiveRecord models you _do not_ need to change your class declarations; else [note this Guide](http://guides.rubyonrails.org/upgrading_ruby_on_rails.html#active-record-models-now-inherit-from-applicationrecord-by-default).
  - If using Airbrake, update your configuration from `api_key` to [`project_key` and new mandatory option `project_id`](https://github.com/airbrake/airbrake/blob/master/docs/Migration_guide_from_v4_to_v5.md#configuration) - the Airbrake migration guide describes numerous other renamed configuration options, so check it carefully.
  - If using Airbrake and manually raising exceptions rather than using the [Hoodoo exception abstraction](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Middleware/ExceptionReporting.html#method-c-report), you must change from `#notify_or_ignore` to plain `#notify`.

- As a maintenance sweep, other gem minimum versions are updated to most-recent in passing but there are no known API changes therein that should impact services. Travis builds still run on PostgreSQL 9.4, as this version or later are still officially supported.

- Resource announcement via the [`Hoodoo::Services::Discovery`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Discovery.html) hierarchy is done even if a service's HTTP host or port are unknown because they couldn't be determined from Rack. This means _local_ resource registration will now proceed, technically resolving a long standing V1 series bug. Discoverers that require both `:host` and `:port` options present will need updating to return `nil` from the remote announce/discovery methods if one or both of the options are missing, or present in the Hash but with `nil` values.

- Compatibility with DDTrace from `master` has been added alongside continuing to support the `feature/rack_dynamic_tracing` branch origin on the `whithajess` fork for compatibility with Hoodoo V1 services.

- The Caller resource now specifies that instances can be shown by primary UUID or fingerprint UUID; both are equally unique. If you are updating a Caller resource implementation, ensure that it records its fingerprint and is compliant with the Hoodoo 2 specification. If you have an ActiveRecord model supporting the resource, adding the line `acquire_with :foo` to that model where `:foo` is the name of the column used to store the fingerprint UUID (without modification) will suffice and use a migration to add an index for that column if there isn't one present already. The fingerprint is expected to be of the same form as any other Hoodoo 32-character UUID (see [`Hoodoo::UUID.generate`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/UUID.html#method-c-generate)). This is intended for API lookup only; **ensure you have test coverage to prove that Sessions can still only be created with a Caller ID, not a fingerprint!**

- New concept of framework-level search/filter query string of `created_by`, to go with fingerprint support introduced back in version 1.19.0. This requires _opt-out_ of services that don't support it, so is slightly backwards-incompatible with existing service code. If an interface already defines such a search key it'll override that provided by Hoodoo. Otherwise-unmodified older services which update to Hoodoo 2 and forget to opt-out will either return an error if the feature is used in an API call, or ignore it and return a list without that particular search/filter field applied.

# Hoodoo v1.x

## 1.19.0 (2017-08-17)

- Now supports ["fingerprints"](https://github.com/LoyaltyNZ/hoodoo/tree/master/docs/api_specification#fingerprints) - an optional UUID associated with a Caller, conveyed in a session payload in the transient store via [`caller_fingerprint`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Session.html#attribute-i-caller_fingerprint) so a resource implementation would read `context.session.caller_fingerprint`) and which should be rendered, if the resource implementation supports persisting and reporting fingerprints, via the `created_by` extensions to [Hoodoo::Presenters::Base#render](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Presenters/Base.html#method-c-render) and [Hoodoo::Presenters::Base#render_in](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Presenters/Base.html#method-c-render_in).

## 1.18.0 (2017-08-17)

- Can set the [`http_open_timeout`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Discovery/ByConvention.html) for `Hoodoo::Client` connections. The [default timeout](https://ruby-doc.org/stdlib-2.4.1/libdoc/net/http/rdoc/Net/HTTP.html) for opening a connection is 60 seconds, which may be too long for some callers.

## 1.17.0 (2017-08-01)

- Higher precision `created_at` (and for sessions, `expires_at`) default time rendering. For some use cases, to-one-second accuracy was insufficient. New method [`Hoodoo::Utilities::standard_datetime`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Utilities.html#method-c-standard_datetime) is used for this.

## 1.16.1 (2017-07-11)

- Maintenance pass including `bundle update` and new Ruby micro versions for development.
- Resolve [issue 212](https://github.com/LoyaltyNZ/hoodoo/issues/212) for Memcached backend in [`Hoodoo::TransientStore`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/TransientStore.html) and implement same behavioural change for the Redis backend. If relevant environment variables for connecting to a real engine are not defined, tests will default back to the mock system again, as they did before version 1.15.0.

## 1.16.0 (2017-06-23)

- Add support for [Datadog](https://www.datadoghq.com) as an alternative to [NewRelic](https://newrelic.com) via the [DDTrace](https://github.com/DataDog/dd-trace-rb) gem.
- Maintenance `bundle update` including moving to latest Database Cleaner for tests, since its most recent incarnation works with the suite again (one test is updated to account for new support for cleaning across multiple database connections).

## 1.15.1 (2017-04-18)

- Fixed a bug in [Hoodoo::Client](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Client.html) which would cause it, during auto-session acquisition, to retry _any_ call that returned an error once in the misguided belief it needed a new session.
- Two minor comment-only fixes added to RDoc documentation around embedding.

## 1.15.0 (2017-02-08)

- Moves the [`Hoodoo::Services::Session` engine](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Session.html) to using [`Hoodoo::TransientStore`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/TransientStore.html). This should be a largely transparent change except for method deprecations described below.

  - The future intent is to allow a configurable choice of transient storage backends for the session engine, though for now, it's still locked to Memcached but just routed through the transient storage abstraction layer.

### Deprecated methods

These will be indefinitely maintained but client code ought to migrate to the new methods when possible.

- [Session#save_to_memcached](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Session.html#method-i-save_to_memcached) - use [Session#save_to_store](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Session.html#method-i-save_to_store) instead (rename only)
- [Session#load_from_memcached!](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Session.html#method-i-load_from_memcached-21) - use [Session#load_from_store!](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Session.html#method-i-load_from_store-21) instead (rename only)
- [Session#delete_from_memcached](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Session.html#method-i-delete_from_memcached) - use [Session#delete_from_store](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Session.html#method-i-delete_from_store) instead (rename only)
- [Session#update_caller_version_in_memcached](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Session.html#method-i-update_caller_version_in_memcached) - use [Session#update_caller_version_in_store](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Session.html#method-i-update_caller_version_in_store) instead, noting that the third parameter in the recommended method is a [`Hoodoo::TransientStore`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/TransientStore.html) instance, not a `Dalli::Client` instance as in the deprecated equivalent.

## 1.14.0 (2017-02-02)

- Introduces the new [Hoodoo::TransientStore](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/TransientStore.html) family, providing a simple abstraction over selectable plug-in storage engine classes. Memcached, Redis and a Memcached/Redis mirror plug-in are available "out of the box".
- Update Ruby versions for Travis to 2.1.10, 2.2.6 and 2.3.3. Base requirement via RBEnv for local development is updated to 2.3.3 (was 2.2.5) via `.ruby-version`. Added Travis entry for Ruby 2.4.0.

## 1.13.0 (2017-02-01)

- In the presenters DSL, [Array](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Presenters/Array.html) and [Hash](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Presenters/Hash.html) now support rendering and validation of simple Array entry or Hash value types such as Strings or Integers, through the use of a new `:type` option. See the [BaseDSL](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Presenters/BaseDSL.html) module's [#array](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Presenters/BaseDSL.html#method-i-array) and [#hash](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Presenters/BaseDSL.html#method-i-hash) RDoc documentation for details.

## 1.12.4 (2017-01-27)

- Comment-only changes to update some RDoc data, especially around the [Hash](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Presenters/Hash.html) type in the [Presenter DSL](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Presenters/BaseDSL.html). For a full list, see [PR 192](https://github.com/LoyaltyNZ/hoodoo/pull/192/files).

## 1.12.1, 1.12.2, 1.12.3 (2016-12-07)

- Test coverage on 1.12.0 overlooked the case where a model defines no search or filter data at all - no calls are made to `search_with` or `filter_with`. In that case, the framework search keys wouldn't be applied. Test coverage added and bug fixed.

- Ensure that with the above fix in place, both subclasses of `Hoodoo::ActiveRecord::Base` and classes explicitly including the Finder module work with both framework-only and custom declarations of search and filter directives.

- Further ensure that subsequent subclassing of such a class works, without having its data set in the parent class and overwritten when the child class instantiates.

## 1.12.0 (2016-12-06)

- New concept of framework-level search/filter query strings, starting with `created_after` and `created_before`. These take values of ISO 8601 subset date/time strings in the URI (with appropriate double encoding per Hoodoo specification!) and by default do greater than / less than comparisons on the `created_at` column in an ActiveRecord model. If you're not using ActiveRecord you will have to provide your own mappings. This is a default opt-in mechanism, where the worst that can happen in theory would be an unaware service with no such matching column being asked to search or filter by the new framework values and thus returning a 500 from a database SQL exception. If you want to specifically opt out, though, do so with new Interface class DSL methods [`Hoodoo::Services::Interface::ToListDSL#do_not_search`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Interface/ToListDSL.html#method-i-do_not_search) and [`Hoodoo::Services::Interface::ToListDSL#do_not_filter`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Interface/ToListDSL.html#method-i-do_not_filter). Same-named entries in an ActiveRecord model's [`Hoodoo::ActiveRecord::Finder::ClassMethods#search_with`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-search_with) and [`Hoodoo::ActiveRecord::Finder::ClassMethods#filter_with`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-filter_with) list, if present, will override the framework allowing you to match in different ways against different named columns if you so wish and ensures unchanged operation of any service which happened to already define same-named search and/or filter keys.

## 1.11.0 (2016-10-03)

- Added enumeration across all values returned by list method with automatic pagination.
  See `enumerate_all` method in [Hoodoo::Client::PaginatedEnumeration](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Client/PaginatedEnumeration.html).

## 1.10.0 (2016-09-23)

- The AMQP log writer back-end ([`Hoodoo::Services::Middleware::AMQPLogWriter`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Middleware/AMQPLogWriter.html)) now allows an alternative routing key to be defined via environment variable `AMQ_ANALYTICS_LOGGING_ENDPOINT`. The default routing key is (still) `platform.logging`, overridden by environment variable `AMQ_LOGGING_ENDPOINT` or by the AMQP log writer being instantiated with an explicit override routing key parameter, as before; however, the additional new environment variable allows, specifically, log data with a code of `analytics` to be sent to a different queue. This means log messages can be "tagged" as for analytical purposes (of some domain defined by the entity creating the software making the log calls) via a code of `analytics` and either left mixed in with all the other log data on the default routing key, or pushed out into its own stream for special case use - e.g. higher or lower priority examination by log data sinks. Only log data with a code (as String or Symbol) of `analytics` is sent via the alternative routing key, assuming one is defined. All other log data is unaffected.

## 1.9.2 (2016-08-29)

- The de-duplication pass for URI query strings would accidentally de-duplicate legitimate duplication strings such as `...?sort=name,created_at&direction=desc,desc` causing incorrect 422 errors. Fixed.

## 1.9.1 (2016-07-11)

- Maintenance `bundle update` and developer default to Ruby 2.2 so that Rack 2 can be used. No API changes.

## 1.9.0 (2016-06-10)

- Added a `csaw_match` method to Hoodoo::ActiveRecord::Finder::SearchHelper that searches for case-sensitive matches with surrounding wildcards.

## 1.8.3 (2016-05-06)

- NewRelic traces now include the action and path to enable better filtering.
- The `dispatch` method in Hoodoo::Services::Middleware is marked for tracing so that the time spent in the implementation can be distinguished from the time spent in the middleware.
- `log_inbound_request` in Hoodoo::Services::Middleware is now a public monkey patchable method called `monkey_log_inbound_request`.

## 1.8.2 (2016-05-04)

- NewRelic cross-application tracing is now enabled in all environments including Production, after it was verified that the performance impact on something already instrumented by NewRelic was undetectable.
- Travis Ruby build versions extended to 2.1.9, 2.2.5 and 2.3.1.

## 1.8.1 (2016-04-18)

- NewRelic cross-application tracing patch does one extra check on availability of a method before enabling itself. This stops service code having to work around edge cases in e.g. migration files, where parts of Hoodoo get included and the monkey patch activates but other parts haven't been included and the patch doesn't see what it expects (https://github.com/LoyaltyNZ/hoodoo/pull/164).

## 1.8.0 (2016-04-13)

- New `Hoodoo::Monkey` engine for official monkey patching. NewRelic cross-application tracing for on-queue inter-resource calls makes use of this mechanism and there are likely to be more to come. The module may be useful for various applications outside the core Hoodoo remit of API services (https://github.com/LoyaltyNZ/hoodoo/pull/162).

- Address https://github.com/LoyaltyNZ/hoodoo/issues/150 in passing (https://github.com/LoyaltyNZ/hoodoo/pull/162/commits/e9c70235bf9e437a681f1b1a8c2182ad0091867c).

## 1.7.0 (2016-04-06)

- New mechanism for estimated, rather than accurate, dataset size counts in lists. This is useful for cases where a persistent storage layer may not be able to provide precise counts in certain circumstances (e.g. persistently high write rates) but can rapidly give estimates. See `Hoodoo::ActiveRecord::Finder::ClassMethods#estimated_count` (https://github.com/LoyaltyNZ/hoodoo/pull/159).

- Fix an issue where Rack would raise an exception for certain malformed `Content-Type` headers. Hoodoo now catches this and returns a more elegant response (https://github.com/LoyaltyNZ/hoodoo/pull/160).

## 1.6.1 (2016-03-29)

- Rapid iteration over 1.6.0. Once I ran it up in a real service test grid I noticed that one of the various automatically logged reports still included full session data regardless of verbose setting. Test coverage improved to spot this and bug fixed.

## 1.6.0 (2016-03-29)

- Sets HTTP response header `X-Error-Logged-Via-Alchemy: yes` if an error has occurred and this error has been reported through at least one `Hoodoo::Services::Middleware::AMQPLogWriter` instance. Some queue-based architectures might include a router/edge splitter component which auto-logs any non-200 response to the queue itself; the new header allows it to detect cases where Hoodoo believes such logging has already taken place and avoid double-logging the error information (https://github.com/LoyaltyNZ/hoodoo/pull/153).

- In the session engine, exceptions raised during attempts to communicate with Memcached sometimes had the originating exception's message omitted in a forwarded exception report. This made connection failure diagnosis very difficult. The originating exception message is now always included (https://github.com/LoyaltyNZ/hoodoo/pull/154 - related drive-by improvement in https://github.com/LoyaltyNZ/hoodoo/pull/155).

- Logging improvements - Alchemy-generic `caller_identity_name` is now included; inbound/result/outbound payloads contain more consistent information; full verbose session detail logging is now switchable through `Hoodoo::Services::Middleware.set_verbose_logging` and by default, verbose logging is now _disabled_. This currently just prevents logging of potentially very verbose permissions and scoping payloads unless you specifically request it. Use `Hoodoo::Services::Middleware.verbose_logging?` to read the setting's current value (https://github.com/LoyaltyNZ/hoodoo/pull/156).

## 1.5.2 (2016-03-18)

- Correct misuse of `===` which wasn't causing any known bugs but might have caused issues for edge cases (spotted by [Rory Stephenson](https://github.com/thelollies)) (https://github.com/LoyaltyNZ/hoodoo/pull/147 / https://github.com/LoyaltyNZ/hoodoo/pull/147/commits/f435aa045444d3bf183e000b3e88b3bc16704863).

- Auto-session acquisition in `Hoodoo::Client` deliberately only retried if an error response came back with just one single "invalid session" entry. More recent changes in Hoodoo introduced middleware conditions under which the payload might contain additional entries, so the client code has been updated to be more resilient and spot any "invalid session" in an error collection. Test coverage bolstered (https://github.com/LoyaltyNZ/hoodoo/pull/147).

- Minor documentation improvement (https://github.com/LoyaltyNZ/hoodoo/pull/146).

## 1.5.1 (2016-03-09)

- No user-facing changes. Internal minor code style change in a test; otherwise, only releasing 1.5.1 to check that an updated RubyGems API key works properly for auto-publishing from Travis (https://github.com/LoyaltyNZ/hoodoo/pull/144 with drive-by internal improvement in https://github.com/LoyaltyNZ/hoodoo/pull/143).

## 1.5.0 (2016-03-02)

- The Alchemy Flux gem has reached major version 1, with some API changes. Hoodoo v1.5.0 and later are compatible with that new API. Previous versions of Hoodoo are either compatible with open source Alchemy Flux v0.x, or the old closed source Alchemy AMQ equivalent only (https://github.com/LoyaltyNZ/hoodoo/pull/141).

## 1.4.1 (2016-02-25)

- Scoping and `require` for use of `SecureRandom` in the UUID module; else Hoodoo could have lookup problems depending on the prevailing Ruby environment (https://github.com/LoyaltyNZ/hoodoo/pull/140).

## 1.4.0 (2016-02-23)

- Introduces `Hoodoo::ActiveRecord::Finder#scoped_in`. This is essentially a public interface onto the partly-internal Support module's `full_scope_for`, allowing safe use of an interface that accesses the generalised mixin-aware scope without getting too close to the internal implementation (https://github.com/LoyaltyNZ/hoodoo/pull/139).

## 1.3.1 (2016-02-18)

- Important fix for historic manual dating variants (version 1.2.x and 1.3.0). UUID validation at the application layer for normal, non-dated resources was broken because of an overlooked piece of stale code. Fixed, including previously missing test coverage to ensure no future regression (https://github.com/LoyaltyNZ/hoodoo/pull/138).

## 1.3.0 (2016-02-17)

- Improved exception reporting through the new `contextual_report` mechanism, which the middleware now uses and the Airbrake and Raygun reporters take advantage of (https://github.com/LoyaltyNZ/hoodoo/pull/136).

## 1.2.3 (2016-02-16)

- Oversight in Creator mixin's `new_in` corrected; it was not accounting for manual dating. Test coverage bolstered. Fix for automatic dating module's `dating_enabled?` method, test coverage also bolstered. Improved documentation for manual dating mixin (https://github.com/LoyaltyNZ/hoodoo/pull/133).

## 1.2.2 (2016-02-15)

- Rapid iteration over 1.2.1 to help avoid a pitfall of inbound timestamps being set to high accuracy but queries based on the same creation time being rounded. If rounded down, the query would fall before the creation time of a resource and 'not find' it. By rounding inbound timestamps, this problem is circumvented (https://github.com/LoyaltyNZ/hoodoo/pull/132).

## 1.2.1 (2016-02-15)

- Rapid iteration over 1.2.0 to recommend a better indexing strategy and remove an at-publishing known problem with 1.2.0 and updates happening faster than the configured date/time accuracy (https://github.com/LoyaltyNZ/hoodoo/pull/131).

## 1.2.0 (2016-02-15)

- All-new "manual" historic dating support. The transparent automatic dating is really nice and transparent for services, but it does come at a heavy cost with migrations (you _really_ need to lean on the `service_shell` generators), is tied into PostgreSQL and for complex associations/join scenarios can degrade performance to unacceptable levels. The counter to this is the lightweight, database-agnostic but much more intrusive "manual" historic dating system, available in `Hoodoo::ActiveRecord::ManuallyDated`. Substantial service changes may be required with the shift from using column `id` over to column `uuid` being the most fiddly and potentially fragile; read the documentation carefully and ensure your service test coverage is comprehensive.

- UUID generator improvements lean on Ruby's `SecureRandom` and remove the external dependency on the UUIDTools gem. It's a really great piece of code but has far more functionality than we need, so it was time to say goodbye.

- Some minor documentation-level (comment) fixes.

- Routine maintenance `bundle update`.

- https://github.com/LoyaltyNZ/hoodoo/pull/129, https://github.com/LoyaltyNZ/hoodoo/pull/130.

## 1.1.3 (2016-02-04)

- More efficient `acquire` method in ActiveRecord `Finder` support module. Now uses the AREL table to only ever make a single database query via `OR`. Related new method `acquisition_scope` is provided for convenience (https://github.com/LoyaltyNZ/hoodoo/pull/128).

## 1.1.2 (2016-02-03)

- New method `acquired_with` in `Finder` module lets callers see what `acquire_with` declarations (if any) have been made, returning a de-duplicated Array of Strings. The `acquire_with` method does the String conversion and de-duplication before storing the acquisition column names internally.

- Use of the `unquoted_column_names` named parameter in `Dating` module methods with no `id` column included would lead to this being added to the _given input Array_, mutating that data accidentally. Now creates a duplicate Array instead.

- Unused support methods `sanitised_column_string` and `sanitised_column_string_for` in Dating module removed; internal callers use `quoted_column_name_string` as a replacement for both.

- https://github.com/LoyaltyNZ/hoodoo/pull/126.

## 1.1.1 (2016-01-29)

- New optional named parameter in ActiveRecord dating support code - `#dated`, `#dated_at` and `#dated_historical_and_current` now let you specify the columns for the underlying `SELECT`s, giving an effect equivalent to that arising when an Array is passed to ActiveRecord's own `#select` method. This can be used to create lighter weight dated queries if only a subset of columns in the result are interesting (https://github.com/LoyaltyNZ/hoodoo/pull/125).

## 1.1.0 (2016-01-26)

- Updated to support new open source Alchemy Flux gem in place of previously stubbed, proprietary Alchemy AMQ gem, for running on-queue under the wider Alchemy architecture (https://github.com/LoyaltyNZ/hoodoo/pull/124).

## 1.0.5 (2016-01-14)

- Base requirement increased from Ruby 2.1.6 to 2.1.8.

- Add `X-Assume-Identity-Of` support, described in the [API specification](https://github.com/LoyaltyNZ/hoodoo/tree/master/docs/api_specification/#http_x_assume_identity_of) in full.

- RDoc generation update via SDoc changes to avoid file modification times within different repositories causing diff noise.

- https://github.com/LoyaltyNZ/hoodoo/pull/119, https://github.com/LoyaltyNZ/hoodoo/pull/120.

## 1.0.4 (2016-01-11)

- Reduce number of queries required in `#acquire` ([David Mitchell](https://github.com/davidamitchell)) https://github.com/LoyaltyNZ/hoodoo/pull/113 - in particular https://github.com/LoyaltyNZ/hoodoo/commit/234178c4aa1610fa913d9f345410f6bc72e9cef4

- Another attempt via Travis support at getting Travis to push to RubyGems when a tagged commit passes tests ([Andrew Hodgkinson](https://github.com/pond)) https://github.com/LoyaltyNZ/hoodoo/pull/114

## 1.0.2, 1.0.3 (2015-12-15)

No functional changes; just some internal or documentation tweaks.

## 1.0.0, 1.0.1 (2015-12-10)

Initial public release. Yanked as part of testing release processes, updating basic `hoodoo.gemspec` data and similar housekeeping.







