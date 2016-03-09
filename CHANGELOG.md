## 1.5.1 (2016-03-09)

* No user-facing changes. Internal minor code style change in a test; otherwise, only releasing 1.5.1 to check that an updated RubyGems API key works properly for auto-publishing from Travis.

## 1.5.0 (2016-03-02)

* The Alchemy Flux gem has reached major version 1, with some API changes. Hoodoo v1.5.0 and later are compatible with that new API. Previous versions of Hoodoo are either compatible with open source Alchemy Flux v0.x, or the old closed source Alchemy AMQ equivalent only.

## 1.4.1 (2016-02-25)

* Scoping and `require` for use of `SecureRandom` in the UUID module; else Hoodoo could have lookup problems depending on the prevailing Ruby environment.

## 1.4.0 (2016-02-23)

* Introduces `Hoodoo::ActiveRecord::Finder#scoped_in`. This is essentially a public interface onto the partly-internal Support module's `full_scope_for`, allowing safe use of an interface that accesses the generalised mixin-aware scope without getting too close to the internal implementation.

## 1.3.1 (2016-02-18)

* Important fix for historic manual dating variants (version 1.2.x and 1.3.0). UUID validation at the application layer for normal, non-dated resources was broken because of an overlooked piece of stale code. Fixed, including previously missing test coverage to ensure no future regression.

## 1.3.0 (2016-02-17)

* Improved exception reporting through the new `contextual_report` mechanism, which the middleware now uses and the Airbrake and Raygun reporters take advantage of.

## 1.2.3 (2016-02-16)

* Oversight in Creator mixin's `new_in` corrected; it was not accounting for manual dating. Test coverage bolstered. Fix for automatic dating module's `dating_enabled?` method, test coverage also bolstered. Improved documentation for manual dating mixin.

## 1.2.2 (2016-02-15)

* Rapid iteration over 1.2.1 to help avoid a pitfall of inbound timestamps being set to high accuracy but queries based on the same creation time being rounded. If rounded down, the query would fall before the creation time of a resource and 'not find' it. By rounding inbound timestamps, this problem is circumvented.

## 1.2.1 (2016-02-15)

* Rapid iteration over 1.2.0 to recommend a better indexing strategy and remove an at-publishing known problem with 1.2.0 and updates happening faster than the configured date/time accuracy.

## 1.2.0 (2016-02-15)

* All-new "manual" historic dating support. The transparent automatic dating is really nice and transparent for services, but it does come at a heavy cost with migrations (you _really_ need to lean on the `service_shell` generators), is tied into PostgreSQL and for complex associations/join scenarios can degrade performance to unacceptable levels. The counter to this is the lightweight, database-agnostic but much more intrusive "manual" historic dating system, available in `Hoodoo::ActiveRecord::ManuallyDated`. Substantial service changes may be required with the shift from using column `id` over to column `uuid` being the most fiddly and potentially fragile; read the documentation carefully and ensure your service test coverage is comprehensive.

* UUID generator improvements lean on Ruby's `SecureRandom` and remove the external dependency on the UUIDTools gem. It's a really great piece of code but has far more functionality than we need, so it was time to say goodbye.

* Some minor documentation-level (comment) fixes.

* Routine maintenance `bundle update`.

## 1.1.3 (2016-02-04)

* More efficient `acquire` method in ActiveRecord `Finder` support module. Now uses the AREL table to only ever make a single database query via `OR`. Related new method `acquisition_scope` is provided for convenience.

## 1.1.2 (2016-02-03)

* New method `acquired_with` in `Finder` module lets callers see what `acquire_with` declarations (if any) have been made, returning a de-duplicated Array of Strings. The `acquire_with` method does the String conversion and de-duplication before storing the acquisition column names internally.

* Use of the `unquoted_column_names` named parameter in `Dating` module methods with no `id` column included would lead to this being added to the _given input Array_, mutating that data accidentally. Now creates a duplicate Array instead.

* Unused support methods `sanitised_column_string` and `sanitised_column_string_for` in Dating module removed; internal callers use `quoted_column_name_string` as a replacement for both.

## 1.1.1 (2016-01-29)

* New optional named parameter in ActiveRecord dating support code - `#dated`, `#dated_at` and `#dated_historical_and_current` now let you specify the columns for the underlying `SELECT`s, giving an effect equivalent to that arising when an Array is passed to ActiveRecord's own `#select` method. This can be used to create lighter weight dated queries if only a subset of columns in the result are interesting.

## 1.1.0 (2016-01-26)

* Updated to support new open source Alchemy Flux gem in place of previously stubbed, proprietary Alchemy AMQ gem, for running on-queue under the wider Alchemy architecture.

## 1.0.5 (2016-01-14)

* Base requirement increased from Ruby 2.1.6 to 2.1.8.

* Add `X-Assume-Identity-Of` support, described in the [API specification](https://github.com/LoyaltyNZ/hoodoo/tree/master/docs/api_specification/#http_x_assume_identity_of) in full.

* RDoc generation update via SDoc changes to avoid file modification times within different repositories causing diff noise.

## 1.0.4 (2016-01-11)

* Reduce number of queries required in `#acquire` ([David Mitchell](https://github.com/davidamitchell)) https://github.com/LoyaltyNZ/hoodoo/pull/113 - in particular https://github.com/LoyaltyNZ/hoodoo/commit/234178c4aa1610fa913d9f345410f6bc72e9cef4

* Another attempt via Travis support at getting Travis to push to RubyGems when a tagged commit passes tests ([Andrew Hodgkinson](https://github.com/pond)) https://github.com/LoyaltyNZ/hoodoo/pull/114


## 1.0.2, 1.0.3 (2015-12-15)

No functional changes; just some internal or documentation tweaks.


## 1.0.0, 1.0.1 (2015-12-10)

Initial public release. Yanked as part of testing release processes, updating basic `hoodoo.gemspec` data and similar housekeeping.
