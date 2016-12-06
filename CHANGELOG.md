## 1.12.1, 1.12.2 (2016-12-07)

* Test coverage on 1.12.0 overlooked the case where a model defines no search or filter data at all - no calls are made to `search_with` or `filter_with`. In that case, the framework search keys wouldn't be applied. Test coverage added and bug fixed.

* Ensure that with the above fix in place, both subclasses of `Hoodoo::ActiveRecord::Base` and classes explicitly including the Finder module work with both framework-only and custom declarations of search and filter directives.

## 1.12.0 (2016-12-06)

* New concept of framework-level search/filter query strings, starting with `created_after` and `created_before`. These take values of ISO 8601 subset date/time strings in the URI (with appropriate double encoding per Hoodoo specification!) and by default do greater than / less than comparisons on the `created_at` column in an ActiveRecord model. If you're not using ActiveRecord you will have to provide your own mappings. This is a default opt-in mechanism, where the worst that can happen in theory would be an unaware service with no such matching column being asked to search or filter by the new framework values and thus returning a 500 from a database SQL exception. If you want to specifically opt out, though, do so with new Interface class DSL methods [`Hoodoo::Services::Interface::ToListDSL#do_not_search`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Interface/ToListDSL.html#method-i-do_not_search) and [`Hoodoo::Services::Interface::ToListDSL#do_not_filter`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Interface/ToListDSL.html#method-i-do_not_filter). Same-named entries in an ActiveRecord model's [`Hoodoo::ActiveRecord::Finder::ClassMethods#search_with`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-search_with) and [`Hoodoo::ActiveRecord::Finder::ClassMethods#filter_with`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/ActiveRecord/Finder/ClassMethods.html#method-i-filter_with) list, if present, will override the framework allowing you to match in different ways against different named columns if you so wish and ensures unchanged operation of any service which happened to already define same-named search and/or filter keys.

## 1.11.0 (2016-10-03)

* Added enumeration across all values returned by list method with automatic pagination.
  See `enumerate_all` method in [Hoodoo::Client::PaginatedEnumeration](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Client/PaginatedEnumeration.html).

## 1.10.0 (2016-09-23)

* The AMQP log writer back-end ([`Hoodoo::Services::Middleware::AMQPLogWriter`](https://cdn.rawgit.com/LoyaltyNZ/hoodoo/master/docs/rdoc/classes/Hoodoo/Services/Middleware/AMQPLogWriter.html)) now allows an alternative routing key to be defined via environment variable `AMQ_ANALYTICS_LOGGING_ENDPOINT`. The default routing key is (still) `platform.logging`, overridden by environment variable `AMQ_LOGGING_ENDPOINT` or by the AMQP log writer being instantiated with an explicit override routing key parameter, as before; however, the additional new environment variable allows, specifically, log data with a code of `analytics` to be sent to a different queue. This means log messages can be "tagged" as for analytical purposes (of some domain defined by the entity creating the software making the log calls) via a code of `analytics` and either left mixed in with all the other log data on the default routing key, or pushed out into its own stream for special case use - e.g. higher or lower priority examination by log data sinks. Only log data with a code (as String or Symbol) of `analytics` is sent via the alternative routing key, assuming one is defined. All other log data is unaffected.

## 1.9.2 (2016-08-29)

* The de-duplication pass for URI query strings would accidentally de-duplicate legitimate duplication strings such as `...?sort=name,created_at&direction=desc,desc` causing incorrect 422 errors. Fixed.

## 1.9.1 (2016-07-11)

* Maintenance `bundle update` and developer default to Ruby 2.2 so that Rack 2 can be used. No API changes.

## 1.9.0 (2016-06-10)

* Added a `csaw_match` method to Hoodoo::ActiveRecord::Finder::SearchHelper that searches for case-sensitive matches with surrounding wildcards.

## 1.8.3 (2016-05-06)

* NewRelic traces now include the action and path to enable better filtering.
* The `dispatch` method in Hoodoo::Services::Middleware is marked for tracing so that the time spent in the implementation can be distinguished from the time spent in the middleware.
* `log_inbound_request` in Hoodoo::Services::Middleware is now a public monkey patchable method called `monkey_log_inbound_request`.

## 1.8.2 (2016-05-04)

* NewRelic cross-application tracing is now enabled in all environments including Production, after it was verified that the performance impact on something already instrumented by NewRelic was undetectable.
* Travis Ruby build versions extended to 2.1.9, 2.2.5 and 2.3.1.

## 1.8.1 (2016-04-18)

* NewRelic cross-application tracing patch does one extra check on availability of a method before enabling itself. This stops service code having to work around edge cases in e.g. migration files, where parts of Hoodoo get included and the monkey patch activates but other parts haven't been included and the patch doesn't see what it expects (https://github.com/LoyaltyNZ/hoodoo/pull/164).

## 1.8.0 (2016-04-13)

* New `Hoodoo::Monkey` engine for official monkey patching. NewRelic cross-application tracing for on-queue inter-resource calls makes use of this mechanism and there are likely to be more to come. The module may be useful for various applications outside the core Hoodoo remit of API services (https://github.com/LoyaltyNZ/hoodoo/pull/162).

* Address https://github.com/LoyaltyNZ/hoodoo/issues/150 in passing (https://github.com/LoyaltyNZ/hoodoo/pull/162/commits/e9c70235bf9e437a681f1b1a8c2182ad0091867c).

## 1.7.0 (2016-04-06)

* New mechanism for estimated, rather than accurate, dataset size counts in lists. This is useful for cases where a persistent storage layer may not be able to provide precise counts in certain circumstances (e.g. persistently high write rates) but can rapidly give estimates. See `Hoodoo::ActiveRecord::Finder::ClassMethods#estimated_count` (https://github.com/LoyaltyNZ/hoodoo/pull/159).

* Fix an issue where Rack would raise an exception for certain malformed `Content-Type` headers. Hoodoo now catches this and returns a more elegant response (https://github.com/LoyaltyNZ/hoodoo/pull/160).

## 1.6.1 (2016-03-29)

* Rapid iteration over 1.6.0. Once I ran it up in a real service test grid I noticed that one of the various automatically logged reports still included full session data regardless of verbose setting. Test coverage improved to spot this and bug fixed.

## 1.6.0 (2016-03-29)

* Sets HTTP response header `X-Error-Logged-Via-Alchemy: yes` if an error has occurred and this error has been reported through at least one `Hoodoo::Services::Middleware::AMQPLogWriter` instance. Some queue-based architectures might include a router/edge splitter component which auto-logs any non-200 response to the queue itself; the new header allows it to detect cases where Hoodoo believes such logging has already taken place and avoid double-logging the error information (https://github.com/LoyaltyNZ/hoodoo/pull/153).

* In the session engine, exceptions raised during attempts to communicate with Memcached sometimes had the originating exception's message omitted in a forwarded exception report. This made connection failure diagnosis very difficult. The originating exception message is now always included (https://github.com/LoyaltyNZ/hoodoo/pull/154 - related drive-by improvement in https://github.com/LoyaltyNZ/hoodoo/pull/155).

* Logging improvements - Alchemy-generic `caller_identity_name` is now included; inbound/result/outbound payloads contain more consistent information; full verbose session detail logging is now switchable through `Hoodoo::Services::Middleware.set_verbose_logging` and by default, verbose logging is now _disabled_. This currently just prevents logging of potentially very verbose permissions and scoping payloads unless you specifically request it. Use `Hoodoo::Services::Middleware.verbose_logging?` to read the setting's current value (https://github.com/LoyaltyNZ/hoodoo/pull/156).

## 1.5.2 (2016-03-18)

* Correct misuse of `===` which wasn't causing any known bugs but might have caused issues for edge cases (spotted by [Rory Stephenson](https://github.com/thelollies)) (https://github.com/LoyaltyNZ/hoodoo/pull/147 / https://github.com/LoyaltyNZ/hoodoo/pull/147/commits/f435aa045444d3bf183e000b3e88b3bc16704863).

* Auto-session acquisition in `Hoodoo::Client` deliberately only retried if an error response came back with just one single "invalid session" entry. More recent changes in Hoodoo introduced middleware conditions under which the payload might contain additional entries, so the client code has been updated to be more resilient and spot any "invalid session" in an error collection. Test coverage bolstered (https://github.com/LoyaltyNZ/hoodoo/pull/147).

* Minor documentation improvement (https://github.com/LoyaltyNZ/hoodoo/pull/146).

## 1.5.1 (2016-03-09)

* No user-facing changes. Internal minor code style change in a test; otherwise, only releasing 1.5.1 to check that an updated RubyGems API key works properly for auto-publishing from Travis (https://github.com/LoyaltyNZ/hoodoo/pull/144 with drive-by internal improvement in https://github.com/LoyaltyNZ/hoodoo/pull/143).

## 1.5.0 (2016-03-02)

* The Alchemy Flux gem has reached major version 1, with some API changes. Hoodoo v1.5.0 and later are compatible with that new API. Previous versions of Hoodoo are either compatible with open source Alchemy Flux v0.x, or the old closed source Alchemy AMQ equivalent only (https://github.com/LoyaltyNZ/hoodoo/pull/141).

## 1.4.1 (2016-02-25)

* Scoping and `require` for use of `SecureRandom` in the UUID module; else Hoodoo could have lookup problems depending on the prevailing Ruby environment (https://github.com/LoyaltyNZ/hoodoo/pull/140).

## 1.4.0 (2016-02-23)

* Introduces `Hoodoo::ActiveRecord::Finder#scoped_in`. This is essentially a public interface onto the partly-internal Support module's `full_scope_for`, allowing safe use of an interface that accesses the generalised mixin-aware scope without getting too close to the internal implementation (https://github.com/LoyaltyNZ/hoodoo/pull/139).

## 1.3.1 (2016-02-18)

* Important fix for historic manual dating variants (version 1.2.x and 1.3.0). UUID validation at the application layer for normal, non-dated resources was broken because of an overlooked piece of stale code. Fixed, including previously missing test coverage to ensure no future regression (https://github.com/LoyaltyNZ/hoodoo/pull/138).

## 1.3.0 (2016-02-17)

* Improved exception reporting through the new `contextual_report` mechanism, which the middleware now uses and the Airbrake and Raygun reporters take advantage of (https://github.com/LoyaltyNZ/hoodoo/pull/136).

## 1.2.3 (2016-02-16)

* Oversight in Creator mixin's `new_in` corrected; it was not accounting for manual dating. Test coverage bolstered. Fix for automatic dating module's `dating_enabled?` method, test coverage also bolstered. Improved documentation for manual dating mixin (https://github.com/LoyaltyNZ/hoodoo/pull/133).

## 1.2.2 (2016-02-15)

* Rapid iteration over 1.2.1 to help avoid a pitfall of inbound timestamps being set to high accuracy but queries based on the same creation time being rounded. If rounded down, the query would fall before the creation time of a resource and 'not find' it. By rounding inbound timestamps, this problem is circumvented (https://github.com/LoyaltyNZ/hoodoo/pull/132).

## 1.2.1 (2016-02-15)

* Rapid iteration over 1.2.0 to recommend a better indexing strategy and remove an at-publishing known problem with 1.2.0 and updates happening faster than the configured date/time accuracy (https://github.com/LoyaltyNZ/hoodoo/pull/131).

## 1.2.0 (2016-02-15)

* All-new "manual" historic dating support. The transparent automatic dating is really nice and transparent for services, but it does come at a heavy cost with migrations (you _really_ need to lean on the `service_shell` generators), is tied into PostgreSQL and for complex associations/join scenarios can degrade performance to unacceptable levels. The counter to this is the lightweight, database-agnostic but much more intrusive "manual" historic dating system, available in `Hoodoo::ActiveRecord::ManuallyDated`. Substantial service changes may be required with the shift from using column `id` over to column `uuid` being the most fiddly and potentially fragile; read the documentation carefully and ensure your service test coverage is comprehensive.

* UUID generator improvements lean on Ruby's `SecureRandom` and remove the external dependency on the UUIDTools gem. It's a really great piece of code but has far more functionality than we need, so it was time to say goodbye.

* Some minor documentation-level (comment) fixes.

* Routine maintenance `bundle update`.

* https://github.com/LoyaltyNZ/hoodoo/pull/129, https://github.com/LoyaltyNZ/hoodoo/pull/130.

## 1.1.3 (2016-02-04)

* More efficient `acquire` method in ActiveRecord `Finder` support module. Now uses the AREL table to only ever make a single database query via `OR`. Related new method `acquisition_scope` is provided for convenience (https://github.com/LoyaltyNZ/hoodoo/pull/128).

## 1.1.2 (2016-02-03)

* New method `acquired_with` in `Finder` module lets callers see what `acquire_with` declarations (if any) have been made, returning a de-duplicated Array of Strings. The `acquire_with` method does the String conversion and de-duplication before storing the acquisition column names internally.

* Use of the `unquoted_column_names` named parameter in `Dating` module methods with no `id` column included would lead to this being added to the _given input Array_, mutating that data accidentally. Now creates a duplicate Array instead.

* Unused support methods `sanitised_column_string` and `sanitised_column_string_for` in Dating module removed; internal callers use `quoted_column_name_string` as a replacement for both.

* https://github.com/LoyaltyNZ/hoodoo/pull/126.

## 1.1.1 (2016-01-29)

* New optional named parameter in ActiveRecord dating support code - `#dated`, `#dated_at` and `#dated_historical_and_current` now let you specify the columns for the underlying `SELECT`s, giving an effect equivalent to that arising when an Array is passed to ActiveRecord's own `#select` method. This can be used to create lighter weight dated queries if only a subset of columns in the result are interesting (https://github.com/LoyaltyNZ/hoodoo/pull/125).

## 1.1.0 (2016-01-26)

* Updated to support new open source Alchemy Flux gem in place of previously stubbed, proprietary Alchemy AMQ gem, for running on-queue under the wider Alchemy architecture (https://github.com/LoyaltyNZ/hoodoo/pull/124).

## 1.0.5 (2016-01-14)

* Base requirement increased from Ruby 2.1.6 to 2.1.8.

* Add `X-Assume-Identity-Of` support, described in the [API specification](https://github.com/LoyaltyNZ/hoodoo/tree/master/docs/api_specification/#http_x_assume_identity_of) in full.

* RDoc generation update via SDoc changes to avoid file modification times within different repositories causing diff noise.

* https://github.com/LoyaltyNZ/hoodoo/pull/119, https://github.com/LoyaltyNZ/hoodoo/pull/120.

## 1.0.4 (2016-01-11)

* Reduce number of queries required in `#acquire` ([David Mitchell](https://github.com/davidamitchell)) https://github.com/LoyaltyNZ/hoodoo/pull/113 - in particular https://github.com/LoyaltyNZ/hoodoo/commit/234178c4aa1610fa913d9f345410f6bc72e9cef4

* Another attempt via Travis support at getting Travis to push to RubyGems when a tagged commit passes tests ([Andrew Hodgkinson](https://github.com/pond)) https://github.com/LoyaltyNZ/hoodoo/pull/114


## 1.0.2, 1.0.3 (2015-12-15)

No functional changes; just some internal or documentation tweaks.


## 1.0.0, 1.0.1 (2015-12-10)

Initial public release. Yanked as part of testing release processes, updating basic `hoodoo.gemspec` data and similar housekeeping.
