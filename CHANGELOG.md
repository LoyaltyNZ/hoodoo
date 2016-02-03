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
