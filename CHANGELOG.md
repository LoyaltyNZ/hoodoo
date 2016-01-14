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
