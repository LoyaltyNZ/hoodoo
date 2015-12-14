# Commit history

Hoodoo was originally created as an internal, closed source component. To ensure no accidental disclosure of company confidential information, the repository commit history was flattened just prior to the open source release, shortly after the v1.0.0 tag was created. For the sake of history, here's the commit log which, for anyone interested, gives some insight into the development of the software.

Entries along the lines of, or including text such as "[proprietary change]" indicate areas where messages had to be edited for confidentiality. In all cases this relates to data types and resource definitions that were originally hosted inside Hoodoo before being moved out into a proprietary internal shared gem, leaving only generic stuff behind.

## 2015-12-10 `9566903`

[Andrew Hodgkinson] Party like it's v1.0.0

## 2015-12-10 `981276d`

[Andrew Hodgkinson] Oversight fix in spec_helper.rb

## 2015-12-10 `d1400de`

[Andrew Hodgkinson] Add a note about the Guides

## 2015-12-10 `c39c855`

[Andrew Hodgkinson] Shuffle code around in spec_helper, fixing the test shutdown bug that could fail to delete a datbase and/or leave the DRb discoverer running.

## 2015-12-10 `4419aed`

[Andrew Hodgkinson] Add contributors list to README.md based on GitHub graph and finish CONTRIBUTING.md based on [proprietary data] and Jekyll

## 2015-12-10 `4a5f775`

[Andrew Hodgkinson] Shuffle the 'docs' folder a bit

## 2015-12-10 `8d8bf15`

[Andrew Hodgkinson] Proof read fixes done, TOC and date updated

## 2015-12-09 `56b9acb`

[Andrew Hodgkinson] Fix TOC

## 2015-12-09 `d616130`

[Andrew Hodgkinson] Update TOC

## 2015-12-09 `4a9563f`

[Andrew Hodgkinson] Remove LNZL-specific search/filter parameters

## 2015-12-09 `bb4d26c`

[Andrew Hodgkinson] Generic Github markdown rendering doesn't like '--'

## 2015-12-09 `e2791d9`

[Andrew Hodgkinson] Provisional release 1 of Hoodoo API Specification, split from Platform API

## 2015-12-07 `c2b0030`

[Andrew Hodgkinson] Bundled RDoc data update

## 2015-12-07 `ddfdac7`

[Andrew Hodgkinson] Merge branch 'master' of https://github.com/LoyaltyNZ/hoodoo

## 2015-12-07 `c21a2d9`

[Andrew Hodgkinson] New 'Creator' module; move 'new_in' into this

## 2015-12-04 `49d9a7d`

[Andrew Hodgkinson] Another minor RDoc fix

## 2015-12-04 `3e8d9ff`

[Andrew Hodgkinson] Fix one test to account for previous commit

## 2015-12-04 `0eaee70`

[Andrew Hodgkinson] Policy change - don't exclude exception reporter mechanism in test/development modes. The service shell already does this in the initializers for Airbrake and Raygun and the Guides will explain about that. This avoids magic overriding in Hoodoo middleware, provides more options for service authors but does still provide sensible defaults when using the shell.

## 2015-12-04 `57f0779`

[Andrew Hodgkinson] Another small RDoc fix

## 2015-12-03 `cf2a880`

[Andrew Hodgkinson] RDoc didn't want to format '++', so change to HTML tags

## 2015-12-03 `f21dcfb`

[Andrew Hodgkinson] Routine bundle update

## 2015-12-03 `1024bbc`

[Andrew Hodgkinson] Remove two documents superseded by Hoodoo Guides material

## 2015-12-03 `e727c1d`

[Andrew Hodgkinson] Fix outdated reference in RDoc summary section

## 2015-12-03 `ff0ddef`

[Andrew Hodgkinson] Update an RDoc reference so it doesn't use a deprecated method name

## 2015-12-03 `c75ffe5`

[Andrew Hodgkinson] Update UUID module's primary key definition recommendation

## 2015-12-03 `09c4a02`

[Andrew Hodgkinson] Documentation update following previous commit

## 2015-12-02 `25ff824`

[Andrew Hodgkinson] Using 'before_validation' caused ID assignment to a nil attribute on updates, With Hilarious Consequences. Prohibit.

## 2015-12-02 `535e4c7`

[Andrew Hodgkinson] Set all secured headers as 'allowed' in the default test session; update documentation for that; fix tests which expect no secured headers to be permitted; add a bit of extra test coverage around non-POST use of X-Resource-UUID

## 2015-12-01 `2c20231`

[Andrew Hodgkinson] Minor documentation fix

## 2015-11-30 `846672d`

[Andrew Hodgkinson] Improve base 'render' documentation

## 2015-11-30 `ac9160f`

[Andrew Hodgkinson] Add ability to specify shell Git repo when making a new service

## 2015-11-27 `192141a`

[Andrew Hodgkinson] Bullet points, courtesy of SDoc update

## 2015-11-27 `670fa6c`

[Andrew Hodgkinson] Pick up a new SDoc revision

## 2015-11-27 `c44c1ca`

[Andrew Hodgkinson] Canned RDoc data update

## 2015-11-27 `68b8679`

[Andrew Hodgkinson] Travis build status image was broken *again* so just give up and get rid of it

## 2015-11-27 `8a79240`

[Andrew Hodgkinson] Canned RDoc data update; extensive due to SDoc improvements

## 2015-11-27 `8c7c0a2`

[Andrew Hodgkinson] Bundle update for newer SDoc

## 2015-11-26 `467a57e`

[Andrew Hodgkinson] Another minor documentation fix

## 2015-11-26 `eb770c0`

[Andrew Hodgkinson] Certain things are for external use now, not internal-only

## 2015-11-26 `93cb257`

[Andrew Hodgkinson] Removed a document now covered by a Guide

## 2015-11-26 `b22c630`

[Andrew Hodgkinson] Another minor docs tweak

## 2015-11-26 `03dc02c`

[Andrew Hodgkinson] Update canned RDoc data with newer generator

## 2015-11-26 `75480d0`

[Andrew Hodgkinson] Use a fork of SDoc for better documentation results

## 2015-11-26 `35e7fb6`

[Andrew Hodgkinson] Routine bundle update

## 2015-11-26 `8bc8c08`

[Andrew Hodgkinson] Update docs after proof read

## 2015-11-26 `f8e146e`

[Andrew Hodgkinson] Bundled RDoc data update

## 2015-11-26 `ad07548`

[Andrew Hodgkinson] Delete the Swagger stuff, since it generates nothing of value in generic Hoodoo

## 2015-11-26 `9f02ce0`

[Andrew Hodgkinson] Tidy up an API wrinkle in Hoodoo::Client

## 2015-11-23 `4866281`

[Andrew Hodgkinson] Merge pull request #97 from LoyaltyNZ/feature/generic

## 2015-11-23 `73b4080`

[Andrew Hodgkinson] Improve test coverage; removal of non-generic resources revealed an omission

## 2015-11-23 `7de00f7`

[Andrew Hodgkinson] Update tests

## 2015-11-23 `e57c2e6`

[Andrew Hodgkinson] Strip out non-generic bits of placeholder Consul discoverer

## 2015-11-20 `19d46e9`

[Andrew Hodgkinson] Add back remaining missing resource. Tests now pass.

## 2015-11-20 `6b42ffd`

[Andrew Hodgkinson] Remove unwanted inclusions

## 2015-11-20 `110280c`

[Andrew Hodgkinson] Add back some things I should've kept

## 2015-11-20 `2c5dcfe`

[Andrew Hodgkinson] Remove things now present in the [proprietary data] gem

## 2015-11-19 `f36ab73`

[Andrew Hodgkinson] Routine bundle update

## 2015-11-17 `2b491e4`

[Andrew Hodgkinson] Add missing file header comments

## 2015-11-17 `1d45981`

[Andrew Hodgkinson] Comment consistency sweep

## 2015-11-17 `7f5b665`

[Andrew Hodgkinson] Comment fix (got broken when Alchemy was merged from two previous gems)

## 2015-11-17 `d1d1b70`

[Andrew Hodgkinson] Remove curious trailing semicolon

## 2015-11-17 `30119dc`

[Andrew Hodgkinson] LGPL v3, with notes and a work-in-progress contribution document

## 2015-11-17 `5bb823e`

[Andrew Hodgkinson] Licence is LGPL

## 2015-11-17 `2dfdd1f`

[Andrew Hodgkinson] Prettify the gemspec

## 2015-11-17 `1420337`

[Andrew Hodgkinson] Merge branch 'master' of https://github.com/LoyaltyNZ/hoodoo

## 2015-11-17 `a10f459`

[Andrew Hodgkinson] Remove redundant 'identity' field in Session

## 2015-11-17 `da47432`

[thelollies] Merge branch 'master' of github.com:loyaltynz/hoodoo

## 2015-11-17 `310073c`

[thelollies] [Proprietary change]

## 2015-11-16 `afe234b`

[Andrew Hodgkinson] Bundled RDoc data update

## 2015-11-16 `98c1149`

[Andrew Hodgkinson] Improved hide-stdout implementation for tests, via service shell

## 2015-11-16 `6b737f1`

[Graham Jenson] Merge pull request #96 from LoyaltyNZ/feature/better_transaction_handling

## 2015-11-16 `2183e35`

[Andrew Hodgkinson] Improve nested transaction handling, per additional RDoc comments

## 2015-11-12 `847ae14`

[Andrew Hodgkinson] Merge pull request #95 [proprietary change]

## 2015-11-12 `b4905e4`

[thelollies] Merge branch 'master' [proprietary change]

## 2015-11-12 `1372d06`

[thelollies] [Proprietary change]

## 2015-11-04 `a6cc8fb`

[Andrew Hodgkinson] Cache Memcached connections within the Session module to avoid creating new ones for every session load and relying (unwisely, it turns out) on closure via the GC.

## 2015-11-02 `18ad89e`

[Andrew Hodgkinson] Revert back to requiring only 2.1.6 (>= 2.1) since 2.2.3 crashes when the test suite runs and there isn't time to work around that right now

## 2015-11-02 `04ed450`

[Andrew Hodgkinson] Bundled RDoc data update

## 2015-11-02 `5c358ca`

[Andrew Hodgkinson] Provide access to the Net::HTTP read_timeout setting via an 'http_timeout' accessor for Hoodoo::Client

## 2015-11-02 `123349f`

[Andrew Hodgkinson] Bundle update

## 2015-11-02 `dff4b9d`

[Andrew Hodgkinson] Update to Ruby 2.2.3 (may cause Ruby interpreter crash during test suite)

## 2015-10-15 `0e35694`

[thelollies] [Proprietary change]

## 2015-10-15 `ce378c3`

[thelollies] Merge branch 'master' [proprietary change]

## 2015-10-15 `984c5b3`

[thelollies] [Proprietary change]

## 2015-10-13 `8a7e6a4`

[thelollies] [Proprietary change]

## 2015-10-06 `e744db4`

[Andrew Hodgkinson] Bundled RDoc data update

## 2015-10-06 `1734e92`

[Andrew Hodgkinson] Merge pull request #93 from LoyaltyNZ/feature/improved_return_data_with_fixes_and_more_tests

## 2015-10-06 `eec6c42`

[Andrew Hodgkinson] RDoc comment correction

## 2015-10-06 `daedfc8`

[Andrew Hodgkinson] Remove CIHash. It isn't used and there's no immediate use case. It can theoretically be recovered from Git history if need be.

## 2015-10-06 `c3fd1e8`

[Andrew Hodgkinson] Remove some redundant code. Technically CIHash isn't needed at all, so the whole thing might get removed in future.

## 2015-10-06 `427b3f2`

[Andrew Hodgkinson] Finalised test coverage and test fixes

## 2015-10-06 `9a7340f`

[Andrew Hodgkinson] Get at HTTP headers in Client responses; various fixes; better test coverage (more to come)

## 2015-10-01 `fc9f4cf`

[thelollies] Merge branch 'master' [proprietary change]

## 2015-10-01 `51608ed`

[Andrew Hodgkinson] Canned RDoc data update

## 2015-10-01 `2628695`

[Andrew Hodgkinson] RDoc note about using deja-vu with endpoints added

## 2015-10-01 `7be4c3d`

[Andrew Hodgkinson] Swap two test lines for consistency & add in a missing check for 'X-Deja-Vu: confirmed' in one middleware test

## 2015-10-01 `313242d`

[thelollies] [Proprietary change]

## 2015-09-30 `addcce5`

[Andrew Hodgkinson] Merge branch 'master' of https://github.com/LoyaltyNZ/hoodoo

## 2015-09-30 `3c5e540`

[Andrew Hodgkinson] Canned RDoc data update

## 2015-09-30 `b958cc1`

[Andrew Hodgkinson] Writer should auto-include ErrorMapping; standardise RDoc for such cases

## 2015-09-30 `590ed98`

[Jeremy Olliver] change Rake-based to Rack-based

## 2015-09-30 `12aada7`

[thelollies] [Proprietary change]

## 2015-09-30 `edfa091`

[Andrew Hodgkinson] Update canned RDoc data

## 2015-09-30 `28051c3`

[Charles Peach] Merge pull request #92 from LoyaltyNZ/feature/permitted_duplicates

## 2015-09-29 `37a1ff7`

[Andrew Hodgkinson] Significantly improved ActiveRecord error mapping

## 2015-09-28 `b2720b9`

[Andrew Hodgkinson] [Proprietary change]

## 2015-09-23 `7d35e8a`

[Andrew Hodgkinson] Refactor to extract Procs to constants with RDoc & unit test, more efficient use of inbound data by not re-parsing DateTimes through use of a combo validator and converter; remove the validation boolean bypass in the errors system as it is only now valid for error pathway cases anyway where revalidation ought to be harmless and a few wasted cycles aren't a major concern (it's an exceptional condition)

## 2015-09-22 `e255d16`

[thelollies] [Proprietary change]

## 2015-09-22 `38c3d74`

[Andrew Hodgkinson] Handy improvement in date and date/time validation method which returns the parsed result in passing for the success case

## 2015-09-22 `cfaeba6`

[Andrew Hodgkinson] RDoc comment improvement

## 2015-09-22 `e3206b1`

[Andrew Hodgkinson] Move HEADER_TO_PROPERTY again; it can't live in the Middleware else requiring 'hoodoo/client' would need to pull in the middleware code too. Put it into its own namespace class instead.

## 2015-09-22 `e12d85b`

[thelollies] [Proprietary change]

## 2015-09-17 `f1aff30`

[Andrew Hodgkinson] Change to use an AR-level error (via grotty flag) for Writer#persist_in DB-only constraint violations, additional test coverage, first go at simulating the race condition check

## 2015-09-16 `6e7d5e6`

[Andrew Hodgkinson] Improved approach (thanks to David M) providing both class and instance persist_in variants, with coverage

## 2015-09-16 `2b63bf0`

[Andrew Hodgkinson] Require Ruby 2.1.6 or later

## 2015-09-15 `e765dfa`

[Andrew Hodgkinson] Inter-resource remote equivalent of previous commit, for belt & braces

## 2015-09-15 `37d39f2`

[Andrew Hodgkinson] Add edge case inter-resource local call test, spot a bug and fix it by improving the middleware's handling of broken service response types in general, with coverage

## 2015-09-15 `4015e5e`

[Andrew Hodgkinson] Ticking off the remaining corners of test coverage, 100% on code and looking good on functionality coverage too

## 2015-09-15 `442aa79`

[Andrew Hodgkinson] RCov revealed some code that refactoring had made redundant - remove & update comments

## 2015-09-15 `4f0bc7d`

[Andrew Hodgkinson] Test coverage ensuring 'deja-vu' works with deletion

## 2015-09-15 `c00b256`

[Andrew Hodgkinson] RDoc code example correction

## 2015-09-15 `b5ebe5e`

[Andrew Hodgkinson] RDoc fixes

## 2015-09-15 `ff81e06`

[Andrew Hodgkinson] RDoc / comment updates

## 2015-09-15 `4c4c9fb`

[Charles Peach] Merge branch 'feature/permitted_duplicates' of github.com:LoyaltyNZ/hoodoo into feature/permitted_duplicates

## 2015-09-15 `9546440`

[Charles Peach] Clean up specs and add defaults to named params

## 2015-09-15 `637a8d0`

[Andrew Hodgkinson] Add coverage on inter-resource local/remote calls where a UUID is specified but permission is not granted. Worthwhile - revealed incorrect early-return semantics in middleware (fixed).

## 2015-09-15 `1effe30`

[Andrew Hodgkinson] Merge branch 'feature/permitted_duplicates' of https://github.com/LoyaltyNZ/hoodoo into feature/permitted_duplicates

## 2015-09-15 `d25f012`

[Andrew Hodgkinson] Good test coverage on local and remote inter-resource calls with resource UUIDs specified , more coming

## 2015-09-15 `c5d8c1d`

[Charles Peach] Add test case in for records that include AR mapping

## 2015-09-15 `ed3fecb`

[Charles Peach] Merge branch 'feature/permitted_duplicates' of github.com:LoyaltyNZ/hoodoo into feature/permitted_duplicates

## 2015-09-15 `89edb5e`

[Charles Peach] Add Initial persist_in helper implementation and working spec

## 2015-09-14 `783eb99`

[Andrew Hodgkinson] Continued test coverage improvements, including inter-resource local and remote pass through (or not) checks of X-Foo HTTP header derived quantities

## 2015-09-14 `4b8c3f6`

[Andrew Hodgkinson] Full test coverage for Hoodoo::Client, with bug fixes arising

## 2015-09-14 `5ed8033`

[Andrew Hodgkinson] Update client spec file to be more flexible and permit option-based test additions

## 2015-09-14 `872bf39`

[Andrew Hodgkinson] Rename X-Instance-Might-Exist because it applies to deletion too; cutsey name horror, but X-Deja-Vu is accurate and rememberable. Deletion case taken care of.

## 2015-09-11 `e48d1eb`

[Andrew Hodgkinson] Shuffle stuff around so that the Middleware can ditch its secured headers approach and roll it all into one, using a single combined structure. Some efficiency improvements too.

## 2015-09-11 `3cd6c59`

[Andrew Hodgkinson] PROPERTY_TO_HEADER's values were never used, so turn it into a Set, not a Hash

## 2015-09-10 `b35d554`

[Andrew Hodgkinson] Implement a much cleaner pattern for all X-Foo headers and associated properties across all of Hoodoo::Client including inter-resource calls, with local calls enforcing header security. Test coverage is required.

## 2015-09-10 `1ff5284`

[Andrew Hodgkinson] Merge branch 'feature/permitted_duplicates' of https://github.com/LoyaltyNZ/hoodoo into feature/permitted_duplicates

## 2015-09-10 `8488a1c`

[Andrew Hodgkinson] Add some overlooked comments describing a private method

## 2015-09-10 `57c9937`

[Charles Peach] Revert "Add side effect behaviour comment to current errors list"

## 2015-09-10 `45abe3f`

[Charles Peach] Merge branch 'feature/permitted_duplicates' of github.com:LoyaltyNZ/hoodoo into feature/permitted_duplicates

## 2015-09-10 `6d1029c`

[Charles Peach] Add side effect behaviour comment to current errors list

## 2015-09-10 `6b821ca`

[Andrew Hodgkinson] White space fix

## 2015-09-10 `fc7626c`

[Andrew Hodgkinson] Lock down Database Cleaner to 1.4.x, since 1.5.0 broke tests

## 2015-09-10 `092b311`

[Andrew Hodgkinson] White space change

## 2015-09-10 `54d05b8`

[Andrew Hodgkinson] Introduce 'writer.rb' pattern in anticipation of e.g. 'persist_in'.

## 2015-09-10 `1bd55af`

[Andrew Hodgkinson] Routine bundle update

## 2015-09-10 `db2c49c`

[Andrew Hodgkinson] Comment fix

## 2015-09-10 `86f7134`

[Andrew Hodgkinson] White space fixes

## 2015-09-10 `a15b532`

[Charles Peach] Rename spec title so that it now matches its implementation

## 2015-09-09 `b7bd08c`

[Charles Peach] Ensure that you cannot send invalid params for duplication header

## 2015-09-09 `e429782`

[Charles Peach] Test coverage for middleware header and status re-writes and remove technical debt on response body format

## 2015-09-09 `fd45386`

[Charles Peach] Ensure gappy style on database name ENV

## 2015-09-09 `4d3694a`

[Charles Peach] Add support into Hoodoo for rewriting responses as 204's if the request was a duplicate

## 2015-08-27 `0eaaecc`

[Andrew Hodgkinson] Merge pull request #89 from LoyaltyNZ/bugfix/validate_outbound_ssl

## 2015-08-25 `f6c6873`

[Andrew Hodgkinson] Merge pull request #91 from LoyaltyNZ/hotfix/validate_dated_at-from

## 2015-08-25 `26342e4`

[Andrew Hodgkinson] Bug fix for update_same_as_create, which did not clear 'required' flags

## 2015-08-24 `2d26644`

[David Mitchell] correctly using nil, remove random text

## 2015-08-24 `eef2add`

[David Mitchell] validating the datetime in dated_from and dated_at

## 2015-08-24 `112dca5`

[davidamitchell] Merge pull request #88 from LoyaltyNZ/feature/dated_from

## 2015-08-19 `9fdd821`

[David Mitchell] master merge

## 2015-08-17 `6837cba`

[Jeremy Olliver] Fixing a typo

## 2015-08-14 `0176118`

[Jeremy Olliver] Put a note in explaining why hoodoo middleware is disabled for this test

## 2015-08-14 `87f6c6b`

[Jeremy Olliver] Refactoring http_spec SSL test to not use 'let'

## 2015-08-14 `a39deea`

[Jeremy Olliver] Tidy up ca_file source comments/documentation:

## 2015-08-14 `e4fa7ef`

[Jeremy Olliver] Clean-up commented out code

## 2015-08-13 `0d369e5`

[Jeremy Olliver] Adding tests that verify both successful and failure conditions of SSL Cert verification

## 2015-08-13 `2db76b2`

[Jeremy Olliver] Add ca_file as an option to discoverer for http client endpoint

## 2015-08-13 `0eb094d`

[Jeremy Olliver] Ensure there are no platform errors in this spec - because it's the only existing test that makes a real http call

## 2015-08-11 `4cafb39`

[Jeremy Olliver] Bugfix: validate SSL Cert chain in Hoodoo::Client

## 2015-08-13 `e5986f1`

[Andrew Hodgkinson] Bundled RDoc data update

## 2015-08-13 `65a0c15`

[Andrew Hodgkinson] Fix an incorrect doc'd example

## 2015-08-13 `737646c`

[davidamitchell] Merge pull request #90 from LoyaltyNZ/hotfix/null_matchers

## 2015-08-13 `b36a0c6`

[Andrew Hodgkinson] PR review -> explicit 'nil' deemed redundant, so removed

## 2015-08-13 `350a7d6`

[Andrew Hodgkinson] Ooops, forgot to commit this file before pushing!

## 2015-08-13 `232f79c`

[Andrew Hodgkinson] SQL 'null' matching fix

## 2015-08-12 `3038a1a`

[Andrew Hodgkinson] Tidy up after previous checkin, including a bit of refactoring and patching up the test coverage

## 2015-08-12 `5d7c423`

[Andrew Hodgkinson] Fix previously heavily broken CORS preflight support

## 2015-08-12 `9d0b22f`

[Andrew Hodgkinson] Small docs tweak #2

## 2015-08-12 `8e2e11d`

[Andrew Hodgkinson] Update canned RDoc data

## 2015-08-12 `61caee5`

[Andrew Hodgkinson] Merge branch 'master' of https://github.com/LoyaltyNZ/hoodoo into feature/dated_from

## 2015-08-11 `9c624c7`

[davidamitchell] Merge pull request #87 from LoyaltyNZ/feature/extended_secure_with

## 2015-08-11 `67e7c92`

[Andrew Hodgkinson] Add test coverage

## 2015-08-11 `52992cd`

[Andrew Hodgkinson] Should set updated_at as well as created_at

## 2015-08-11 `0b5a87c`

[Andrew Hodgkinson] Additional documentation

## 2015-08-11 `52d5510`

[Andrew Hodgkinson] The service support component, with a cheap and nasty implementation for now; again, no test coverage yet

## 2015-08-11 `b124cff`

[Andrew Hodgkinson] In-passing performance improvement in the Hoodoo::ActiveRecord::Support module

## 2015-08-11 `77fcab8`

[Andrew Hodgkinson] First 'draft' in code of X-Dated-From support, without any service persistence layer help and without test coverage

## 2015-08-11 `fb4c132`

[Andrew Hodgkinson] Comment-only change to advise future maintainers of an intentional but subtle aspect of the test coverage

## 2015-08-11 `f99f09a`

[Andrew Hodgkinson] Canned RDoc data update

## 2015-08-11 `d98b36b`

[Andrew Hodgkinson] Important bug fix for subclasses of subclasses of (sic.) Hoodoo::ActiveRecord::Base where dating/security/translation declarations are made in the first subclass, and supposed to be picked up by the end-of-chain subclass

## 2015-08-10 `3833664`

[Andrew Hodgkinson] Test coverage for PostgreSQL search helpers now that PostgreSQL is present during tests; add all-wildcard generic and PostgreSQL helpers too, with tests

## 2015-08-10 `b3c0a40`

[Andrew Hodgkinson] Extend secure_with to include search_with-like matcher Proc ability

## 2015-08-07 `0cd0c77`

[Andrew Hodgkinson] More sensible 'spec' exclusion filter for RCov

## 2015-08-06 `4ed04c1`

[Andrew Hodgkinson] Update canned RDoc data

## 2015-08-06 `2f05c36`

[Andrew Hodgkinson] Merge branch 'master' of https://github.com/LoyaltyNZ/hoodoo

## 2015-08-06 `524ffa5`

[davidamitchell] Merge pull request #84 from LoyaltyNZ/hotfix/improved_ar_accessors

## 2015-08-06 `e90ba82`

[Andrew Hodgkinson] Fix a static routing error (never used, but just in case...)

## 2015-08-04 `ca6fc85`

[Andrew Hodgkinson] Add placeholder API document

## 2015-08-04 `d185e0e`

[Andrew Hodgkinson] Canned RDoc data update

## 2015-08-03 `fa4fb24`

[Andrew Hodgkinson] Minor updates after PR feedback

## 2015-07-31 `21e6c93`

[Andrew Hodgkinson] Merge branch 'master' into hotfix/improved_ar_accessors

## 2015-07-31 `6ebe62f`

[Andrew Hodgkinson] Merge pull request #85 from LoyaltyNZ/hotfix/drb_again

## 2015-07-31 `0fdb1b0`

[Andrew Hodgkinson] General DRb fixes, including proper use of  and just maybe finally stamping out DRB timeouts, albeit via an ugly global variable holding a queue...

## 2015-07-31 `9ec6e05`

[Andrew Hodgkinson] 'Is it just slow' timeout hack, temporary

## 2015-07-31 `486b685`

[Andrew Hodgkinson] File included by mistake; remove

## 2015-07-31 `588b4ed`

[Andrew Hodgkinson] Reinstate full inclusion of all mixins in the ActiveRecord support optional base class

## 2015-07-31 `6a8fa66`

[Andrew Hodgkinson] Comment-only formatting fix

## 2015-07-31 `ff560ee`

[Andrew Hodgkinson] Explicit test coverage for the Support module, bringing total coverage back up to 100% non-trivial again

## 2015-07-31 `0bd2138`

[Andrew Hodgkinson] Test coverage in middleware for new Client exception rescue code, plus better coverage of previous exception handling and new exception handling in pure Hoodoo::Client test code

## 2015-07-30 `5e97643`

[Andrew Hodgkinson] Slight refactor and API change on Dated module so it must be explicitly activated, rather than being magically activated just by including the module

## 2015-07-30 `40969a0`

[Andrew Hodgkinson] Unrelated comment-only change to ensure future maintainers don't slip up

## 2015-07-30 `547535a`

[Andrew Hodgkinson] Unrelated but useful tweak for Client to report errors more clearly and handle arbitrary exceptions in a pure Client, non-Hoodoo-middleware context

## 2015-07-29 `2038e0b`

[Andrew Hodgkinson] Use ActiveSupport code that's present if ActiveRecord is present to clean up and fix a serious shortcoming in the AR extensions behaviour regarding inheritance, given the previous use of class (hierarchy) variables versus 'inherited' class instance variables via AS's 'class_accessor'.

## 2015-07-29 `3d8efb5`

[Andrew Hodgkinson] Update Airbrake / Raygun comments

## 2015-07-28 `f29dc46`

[Andrew Hodgkinson] In non-production environments, catch serialization failures for on-queue behaviour more elegantly at the expense of performance

## 2015-07-28 `b1980f9`

[Andrew Hodgkinson] Update canned RDoc data

## 2015-07-28 `5a2f1f9`

[Andrew Hodgkinson] Minor comment / white space / coding style sweep

## 2015-07-28 `f9adc90`

[Andrew Hodgkinson] Remove pending test from base_spec.rb as base.rb no longer includes Translatable by default

## 2015-07-28 `e0c2583`

[thelollies] Use postgres as default database.

## 2015-07-28 `248f8f8`

[davidamitchell] Merge pull request #70 from LoyaltyNZ/feature/effective_dating

## 2015-07-28 `3724f7f`

[David Mitchell] minor doco changes

## 2015-07-28 `2b3f0db`

[David Mitchell] minor doco changes

## 2015-07-27 `1147897`

[davidamitchell] Merge pull request #78 [proprietary change]

## 2015-07-27 `08c88b2`

[Andrew Hodgkinson] Merge pull request #76 [proprietary change]

## 2015-07-27 `9d8eb72`

[Jeremy Olliver] Merge pull request #77 from LoyaltyNZ/feature/http_proxy_override

## 2015-07-27 `caff42d`

[Rory Stephenson] Merge pull request #82 from LoyaltyNZ/revert-81-revert-80-hotfix/session_api_fix_and_improve

## 2015-07-27 `1480088`

[Rory Stephenson] Revert "Revert "Fix an ambiguity in the Session API and clean up return values…""

## 2015-07-27 `37fdd1a`

[Rory Stephenson] Merge pull request #81 from LoyaltyNZ/revert-80-hotfix/session_api_fix_and_improve

## 2015-07-27 `ef96073`

[Rory Stephenson] Revert "Fix an ambiguity in the Session API and clean up return values…"

## 2015-07-27 `cdd7fde`

[Rory Stephenson] Merge pull request #80 from LoyaltyNZ/hotfix/session_api_fix_and_improve

## 2015-07-27 `4e48b3a`

[Andrew Hodgkinson] Fix an ambiguity in the Session API and clean up return values, making them sane via Symbols (at a *very* slight performance penalty) rather than the previous confusing true/false/nil mess

## 2015-07-24 `e8d266c`

[thelollies] Specify that effective_end must be in UTC when deleting a dated record.

## 2015-07-24 `731a315`

[thelollies] Add more detail to the dated documentation

## 2015-07-24 `de72371`

[thelollies] Merge branch 'master' into feature/effective_dating

## 2015-07-24 `9acea8d`

[thelollies] Minor comment typos and rename history_column_mapping to dated_history_column_mapping to avoid namespace collisions.

## 2015-07-24 `3ae4901`

[Andrew Hodgkinson] Be consistent about using symbolised naming of class variables, not strings - thanks Rory! :-)

## 2015-07-24 `5c665dc`

[Andrew Hodgkinson] Merge branch 'master' of https://github.com/LoyaltyNZ/hoodoo

## 2015-07-24 `a6f7f67`

[Andrew Hodgkinson] Default platform_errors collections now have a 200 code not 500; far more friendly for people directly checking the status code without checking for an empty collection first

## 2015-07-24 `a8ce4a6`

[thelollies] Comment dated_with class method.

## 2015-07-24 `5907455`

[thelollies] Tidy up the history model constant for dated models.

## 2015-07-24 `a7f4cd3`

[thelollies] Add dating example and remove primary key customisation.

## 2015-07-24 `ca5bf6d`

[thelollies] Remove check for activerecord base including Translated, as it no longer does

## 2015-07-24 `bcf98e8`

[thelollies] Remove translated from default activerecord extensions and add blurb for dated.

## 2015-07-24 `085e369`

[Andrew Hodgkinson] Merge pull request #79 from LoyaltyNZ/feature/backdated_purchases

## 2015-07-24 `298bcfd`

[Joseph Leniston] [Proprietary change]

## 2015-07-23 `6600015`

[thelollies] Incorporate PR comments.

## 2015-07-23 `112d829`

[Joseph Leniston] [Proprietary change]

## 2015-07-23 `dc5535c`

[thelollies] Fix alignment.

## 2015-07-22 `6a401fd`

[Andrew Hodgkinson] Make sure JSON is require'd for any file that uses it and ensure the global '::' prefix is present; in 'http_based.rb', just use '.generate' not '.fast_generate', like everywhere else

## 2015-07-22 `e84f86f`

[Andrew Hodgkinson] Code was assuming ActiveSupport presence erroneously

## 2015-07-22 `73b8fd2`

[thelollies] WIP incorporate PR comments.

## 2015-07-22 `72dd6da`

[Joseph Leniston] [Proprietary change]

## 2015-07-21 `f46be69`

[thelollies] Fix specs.

## 2015-07-21 `a7d818d`

[thelollies] Remove old effective dating file.

## 2015-07-21 `3eddbf0`

[thelollies] WIP specs randomly failing but functionality is working.

## 2015-07-21 `212237c`

[thelollies] Rename .at to .dated

## 2015-07-21 `c38d6d6`

[thelollies] Merge master.

## 2015-07-21 `1d0808c`

[thelollies] Remove incomplete specs in lieu of new ones when new Hoodoo finder functionality is merged.

## 2015-07-20 `303686a`

[Andrew Hodgkinson] Improved test coverage, including mock coverage for to-be-done things so that RCov 100% is meaningful again and accidental coverage omissions will be easier to see

## 2015-07-20 `eeb213a`

[Andrew Hodgkinson] Update outdated test

## 2015-07-20 `387d650`

[Andrew Hodgkinson] Adding in previously overlooked test for custom routing in by-convention discoverer

## 2015-07-20 `24b9034`

[Joseph Leniston] [Proprietary change]

## 2015-07-20 `310882a`

[Andrew Hodgkinson] Allow proxy override for HTTP endpoints, with limited (mocked) test coverage

## 2015-07-20 `81f6607`

[Andrew Hodgkinson] Update slightly outdated RDoc comments

## 2015-07-20 `bec4638`

[Andrew Hodgkinson] Update not-really-by-Consul ByConsul discoverer resource table

## 2015-07-20 `4f16737`

[Andrew Hodgkinson] Bundled RDoc data update [ci skip]

## 2015-07-20 `2e6dd49`

[Andrew Hodgkinson] Change to a custom dated_at write accessor to tidy up code and increase flexibility for direct-attribute-setting calling code

## 2015-07-20 `9b2af69`

[Rory Stephenson] Merge pull request #75 from LoyaltyNZ/feature/dated_at

## 2015-07-17 `de7788c`

[Joseph Leniston] [Proprietary change]

## 2015-07-17 `62a5f14`

[Rory Stephenson] Merge pull request #74 from LoyaltyNZ/feature/finder_pattern

## 2015-07-17 `f2f0b3e`

[Andrew Hodgkinson] Completed test coverage; bug fixes arising

## 2015-07-16 `c192f7c`

[Andrew Hodgkinson] Test coverage for changes in Client, with fixes

## 2015-07-16 `8dbd56e`

[Andrew Hodgkinson] Comment-only changes

## 2015-07-16 `25c547e`

[David Mitchell] fix up of some counting issues

## 2015-07-15 `f361b3b`

[Andrew Hodgkinson] WIP on dated_at support with locale etc. passthrough in local inter-resource calls

## 2015-07-15 `3448766`

[David Mitchell] master merge

## 2015-07-15 `2cd2213`

[thelollies] Merge.

## 2015-07-14 `2c06e48`

[Andrew Hodgkinson] Remove outdated comment; include everything in 'base.rb'

## 2015-07-14 `15c385d`

[Andrew Hodgkinson] Comment updates on #acquire_in and #list_in

## 2015-07-14 `44e0751`

[Andrew Hodgkinson] Introduce a more extensible pattern for the ActiveRecord finder stuff. Comment updates on #acquire_in and #list_in TBD

## 2015-07-14 `1375887`

[Andrew Hodgkinson] Comment-only typo fix - 'UUDI' => 'UUID'

## 2015-07-13 `7df0321`

[Andrew Hodgkinson] Related to 83bf41edd005888cfd9eef88840e84e1932259d8 - this file was overlooked

## 2015-07-13 `ca476a6`

[Andrew Hodgkinson] Fractionally more efficient 'to_integer?' implementation

## 2015-07-13 `de73562`

[Andrew Hodgkinson] Commit b47acac78fb2b433a5fb8a97795779675a0fa504 looked good, so standardised on this approach for all implementation-related URLs in 'utilities.rb'

## 2015-07-13 `b47acac`

[Andrew Hodgkinson] RDoc-only change; moved a comment providing a URL linked to implementation details into the code where it belongs, rather than the encapsulating method's description

## 2015-07-13 `1e4e312`

[Andrew Hodgkinson] RDoc-only change; removed a warning since the issue in question is fixed in the minimum Ruby version required by Hoodoo

## 2015-07-13 `b5258df`

[Andrew Hodgkinson] Bundled RDoc data updated

## 2015-07-13 `83bf41e`

[Andrew Hodgkinson] Comment-only fixes to RDoc syntax for a few method parameter lists

## 2015-07-13 `198187c`

[thelollies] WIP extracting header for x-dated-at.

## 2015-07-13 `5f60f42`

[thelollies] Remove old TODO.

## 2015-07-13 `11ddfe9`

[thelollies] Fix database connection in after(:suite) of spec_helper.rb

## 2015-07-13 `0039ddc`

[thelollies] Use same type for acquire_with columns due to using postgres instead of sqlite.

## 2015-07-13 `d0093fd`

[thelollies] Merge master.

## 2015-07-13 `2741f53`

[thelollies] Attempt to fix travis issues.

## 2015-07-13 `e756d13`

[Andrew Hodgkinson] Bundled RDoc data updated

## 2015-07-13 `1ddb0fa`

[Andrew Hodgkinson] Improve comments re. required datatypes of fields used in the finder #acquire method and related methods

## 2015-07-13 `0467f7e`

[thelollies] Add postgres

## 2015-07-13 `349d005`

[thelollies] Correct specs.

## 2015-07-10 `b2652e1`

[thelollies] WIP fixing finder.

## 2015-07-10 `bfc2428`

[Andrew Hodgkinson] Bundled RDoc data updated

## 2015-07-10 `13f080b`

[Andrew Hodgkinson] Merge branch 'master' of https://github.com/LoyaltyNZ/hoodoo

## 2015-07-10 `ae677e7`

[Andrew Hodgkinson] Fix Hash#walk for a usage edge case I'd overlooked

## 2015-07-10 `e37e786`

[Wayne] Merge pull request #72 from LoyaltyNZ/feature/improved_search_api

## 2015-07-10 `6863c37`

[Rory Stephenson] Merge pull request #73 from LoyaltyNZ/feature/civilised_headers

## 2015-07-09 `0c9b3bd`

[Andrew Hodgkinson] Add in 'context.request.headers' for more civilised header access within services

## 2015-07-09 `ad131c2`

[Andrew Hodgkinson] Helper methods to make search/filter-with easier to use

## 2015-07-08 `f888371`

[Andrew Hodgkinson] Canned RDoc data update, with comment-only fixes in 'interface.rb'

## 2015-07-08 `823d343`

[Andrew Hodgkinson] Back up to 100% test coverage, with a few fixes and some dead code removal

## 2015-07-08 `f38a98f`

[Andrew Hodgkinson] Address the 'required field in to_update block causes rejection' issue, with a lot of code formatting love in passing for the presenter layer; extra test coverage on the new #walk method to follow

## 2015-07-08 `96c26d9`

[thelollies] De-beautify effective dating.

## 2015-07-08 `0ff28b3`

[thelollies] Add method to get all historical and current records.

## 2015-07-08 `1c0cac8`

[Andrew Hodgkinson] Clarify Swagger README.md

## 2015-07-08 `7f391e6`

[Andrew Hodgkinson] Remove the local copies of the Swagger UI and spec in favour of a README.md file that describes the tool and includes URIs pointing to important related resources.

## 2015-07-08 `f4d5063`

[Andrew Hodgkinson] Unexpected change in Gemfile.lock pushed

## 2015-07-08 `d52cef4`

[Andrew Hodgkinson] Mock updated Hoodoo API in 'make.rb' so that it can extract the API version from the Version interface code in service_utility again

## 2015-07-08 `c7203b5`

[Andrew Hodgkinson] Swagger generator bundle update

## 2015-07-07 `d7f7b31`

[thelollies] Change effective_at to at

## 2015-07-07 `f714eb4`

[thelollies] Match case of history table name to effective dating generated table name.

## 2015-07-07 `5adfbcd`

[thelollies] Formatting

## 2015-07-07 `54e4e68`

[thelollies] Combine list_at and find_at into effective_at which can then be constrained via further scoping.

## 2015-07-07 `4e99496`

[thelollies] Revert configurable uuid changes.

## 2015-07-07 `3c8fb53`

[thelollies] Simplify history table name setter/getter.

## 2015-07-07 `84e2d29`

[thelollies] Fix comment and remove byebug require form spec.

## 2015-07-06 `b274bc8`

[Andrew Hodgkinson] Bundle update and show the Swagger generator some love - knows about more services, relevant branches, doesn't try to read local service data, more compliant Swagger output (per latest updates to e.g. editor UI at editor.swagger.io).

## 2015-07-06 `ffe7fbe`

[thelollies] Working and specced for listing and finding of effective dated resources.

## 2015-07-06 `0cacfbe`

[Andrew Hodgkinson] Very minor comment-only fix, with associated RDoc data update

## 2015-07-03 `21455b7`

[thelollies] WIP [skip ci]

## 2015-07-03 `f845ea3`

[Andrew Hodgkinson] RDoc data update

## 2015-07-03 `36d075b`

[Wayne] Merge pull request #68 from LoyaltyNZ/feature/improved_query_string_handling

## 2015-07-03 `79b3d1d`

[Andrew Hodgkinson] Modify sort key & direction behaviour to be less permissive following PR comments

## 2015-07-03 `716088f`

[Rory Stephenson] Merge pull request #69 from LoyaltyNZ/feature/legacy_tags_fix

## 2015-07-03 `ce831ec`

[Joseph Leniston] [Proprietary change]

## 2015-07-02 `6b6713a`

[Andrew Hodgkinson] Close a small hole where certain random test orders would leave Hoodoo thinking there were public actions and bypassing a particular 401 check, leaning instead on a later one, causing RCov to report reduced code coverage

## 2015-07-02 `7bca7da`

[Andrew Hodgkinson] Add comprehensive test coverage

## 2015-07-02 `964c189`

[Andrew Hodgkinson] Improved query string handling; passes tests, but no new coverage for new features has been added yet

## 2015-07-02 `d862e2a`

[Andrew Hodgkinson] Add bypass-uniqueness-step parameter to query string processor support method

## 2015-07-02 `b998d42`

[Andrew Hodgkinson] Add a method useful for query string processing, with tests

## 2015-07-02 `7d8ea7c`

[thelollies] WIP

## 2015-07-01 `2b7716f`

[Graham Jenson] Merge pull request #67 from LoyaltyNZ/feature/better_logging

## 2015-07-01 `0e2395a`

[Graham Jenson] Merge branch 'master' into feature/better_logging

## 2015-07-01 `232a40b`

[Andrew Hodgkinson] Belatedly replace (a+b).uniq with (a|b) in the one place it's used, for a minor speed improvement during edge case operations, or for clients that use the hash diff a lot

## 2015-06-30 `3306b25`

[Andrew Hodgkinson] Fix issue described by https://trello.com/c/lPmD9b5q/82-hoodoo-errors-http-status-code-is-not-always-an-integer-and-its-data-type-is-not-made-clear-in-rdocs - http_status_code values are Integers, always

## 2015-06-30 `4010a9e`

[thelollies] Add spec for find_at getting no results. Add list_at specs.

## 2015-06-30 `e117854`

[thelollies] Simplify find_at implementation and add documentation for find_at and list_at.

## 2015-06-30 `62bff70`

[thelollies] Effective dating working. Still needs list_at specs.

## 2015-06-30 `93899ce`

[thelollies] Fix uuid validators.

## 2015-06-30 `b5c8c59`

[Andrew Hodgkinson] Previous commit didn't resolve Travis issues; increasing timeout to see if that's all it was, or if this really is still the same class as failure as before

## 2015-06-30 `304d683`

[Andrew Hodgkinson] Stop using Ruby Timeout class to try and alleviate DRb timeouts in the test suite, especially when running under Travis. It's unlikely that this will fix it, but there might be an interaction with Timeout (see URLs in comments in changed code) and DRb. In any case, the replace code is smaller and easier to understand. Only DRb discovery is modified, so on-grid behaviour will not change.

## 2015-06-29 `cfe1d2e`

[Andrew Hodgkinson] Merge pull request #66 from LoyaltyNZ/feature/currency_grouping_level

## 2015-06-29 `e81db08`

[Joseph Leniston] Minor currency changes

## 2015-06-29 `95a3c54`

[thelollies] WIP effective dating.

## 2015-06-29 `3a25953`

[thelollies] Configurable UUID column.

## 2015-06-29 `ba8a6a8`

[Andrew Hodgkinson] Log target resource, version and action; get rid of well-intentioned but never implemented (and not really that useful) 'target interface for error', intended to show the top-level resource down at an arbitrary inter-resource level (interaction ID tracing takes care of that)

## 2015-06-26 `57ce58e`

[Andrew Hodgkinson] Routine maintenance bundle update, which pulled in some surprising v4.2.3 updates to Rails-related gems; test suite still passes.

## 2015-06-26 `5a5259c`

[Andrew Hodgkinson] Canned RDoc data update

## 2015-06-26 `5b10d08`

[Andrew Hodgkinson] Comment changes only. Replace outdated references to StructuredLogger with Hoodoo::Logger. Was overlooked when the logging refactor took places months ago.

## 2015-06-24 `654efa5`

[Joseph Leniston] [Proprietary change]

## 2015-06-24 `42b4285`

[Andrew Hodgkinson] Merge pull request #62 from LoyaltyNZ/feature/use_tag_resource_for_products

## 2015-06-24 `bc57a77`

[thelollies] Spelling fixes.

## 2015-06-24 `a02c794`

[thelollies] [Proprietary change]

## 2015-06-24 `ab0858f`

[Joseph Leniston] [Proprietary change]

## 2015-06-23 `e891553`

[Rory Stephenson] Merge pull request #65 from LoyaltyNZ/feature/authorised_http_headers

## 2015-06-23 `d24594b`

[Andrew Hodgkinson] Fix minor logging typo

## 2015-06-23 `ea20baa`

[Andrew Hodgkinson] Updates after PR #65 review, including test coverage & fix for potential edge case

## 2015-06-22 `dc75c6c`

[Andrew Hodgkinson] Refactor the test code to clean it up / remove duplication and improve coverage on edge cases up to 100%

## 2015-06-22 `e539148`

[Andrew Hodgkinson] Implement secure headers, with test coverage for the only one currently defined - X-Resource-UUID

## 2015-06-18 `21a802a`

[thelollies] [Proprietary change]

## 2015-06-17 `cc39569`

[thelollies] [Proprietary change]

## 2015-06-17 `a4c0020`

[Andrew Hodgkinson] Update Alchemy to allow update to Rack (to v1.6.2), for security patch.

## 2015-06-17 `31bf6dd`

[Andrew Hodgkinson] Fix some tests (pure test-only issues), with some extra comments / white space fixes in Hoodoo code which arose from ambiguities found while attempting to diagnose the problems with those tests.

## 2015-06-17 `1f0fb05`

[Andrew Hodgkinson] Track ActiveRecord/ActiveSupport 4.2 not 4.1 for local development only; no service impact

## 2015-06-15 `e0c840f`

[Andrew Hodgkinson] Merge pull request #61 from LoyaltyNZ/feature/tag_resources

## 2015-06-15 `1b0c532`

[thelollies] [Proprietary change]

## 2015-06-12 `f60ffd6`

[thelollies] [Proprietary change]

## 2015-06-10 `f2966f5`

[Andrew Hodgkinson] Canned RDoc data update (with white space fix in source file)

## 2015-06-10 `d6cc54e`

[Wayne] Merge pull request #60 from LoyaltyNZ/feature/custom_convention_routes_and_client_discoverer

## 2015-06-10 `286441d`

[Andrew Hodgkinson] Comment fix

## 2015-06-10 `b4965aa`

[Andrew Hodgkinson] Test coverage

## 2015-06-10 `19f9ad9`

[Andrew Hodgkinson] Obvious typo is obvious

## 2015-06-10 `39e5f93`

[Andrew Hodgkinson] Initial coding work, no test coverage or attempts to run it yet

## 2015-06-05 `dfceb42`

[thelollies] [Proprietary change]

## 2015-06-05 `76d0703`

[David Mitchell] stashing in the cloud

## 2015-06-04 `e9b9da9`

[Andrew Hodgkinson] Merge branch 'master' of https://github.com/LoyaltyNZ/hoodoo

## 2015-06-04 `1448461`

[Andrew Hodgkinson] Excise AMQEndpoint; use new AlchemyAMQ only

## 2015-06-04 `2a3e728`

[davidamitchell] Merge pull request #57 [proprietary change]

## 2015-06-04 `22fe150`

[Joseph Leniston] [Proprietary change]

## 2015-06-03 `c80d717`

[David Mitchell] and tests

## 2015-06-03 `d1a8d11`

[David Mitchell] all for setting of start and end date field names

## 2015-06-02 `f2b1c8c`

[Andrew Hodgkinson] Update bundled RDoc data following PR merge

## 2015-06-02 `8d4d969`

[Andrew Hodgkinson] Merge pull request #56 from LoyaltyNZ/hotfix/rdoc_improvement

## 2015-05-29 `c371d1f`

[David Mitchell] starting the testing

## 2015-05-25 `7c0c2d9`

[Andrew Hodgkinson] RDoc code sample improvement

## 2015-05-21 `c460cf0`

[Andrew Hodgkinson] Describe workflow

## 2015-05-18 `dd1238f`

[Andrew Hodgkinson] [Proprietary change]

## 2015-05-15 `715c8e7`

[Andrew Hodgkinson] White space change only

## 2015-05-08 `0869b13`

[Andrew Hodgkinson] Canned RDoc data update

## 2015-05-07 `d2bea25`

[Andrew Pett] Merge pull request #55 from LoyaltyNZ/hotfix/bound_offset_and_limit

## 2015-05-07 `66436f8`

[Andrew Hodgkinson] Complain about < 1 limit or < 0 offset values

## 2015-05-04 `eec52b2`

[davidamitchell] Merge pull request #53 from LoyaltyNZ/feature/improved_rendering

## 2015-05-03 `9d46846`

[Andrew Hodgkinson] Fix minor typo

## 2015-05-01 `8ecafe4`

[Andrew Hodgkinson] Full test coverage

## 2015-05-01 `10a64b8`

[Andrew Hodgkinson] Better test coverage for secure_with extensions

## 2015-05-01 `c2df990`

[Andrew Hodgkinson] Documentation

## 2015-04-30 `4ed7db2`

[Andrew Hodgkinson] WIP on improved rendering (embed, reference, "secured_with") support.

## 2015-04-28 `a7f552b`

[Andrew Hodgkinson] Remove legacy/support logging fields

## 2015-04-22 `4c7cf6c`

[Andrew Hodgkinson] ...and back again

## 2015-04-22 `cd418bc`

[Andrew Hodgkinson] That didn't work; trying again

## 2015-04-22 `f188602`

[Andrew Hodgkinson] Revert previous commit, restoring Master to safety

## 2015-04-22 `3fcb4f1`

[Andrew Hodgkinson] Revert previous commit (no improvement) AND DISABLE ENTIRELY queue logging by not sending via Alchemy. This checks performance impact of basic log packet generation within Hoodoo.

## 2015-04-22 `2cf85a6`

[Andrew Hodgkinson] Highly experimental change to switch AMQP logger over to a SlowWriter subclass, which uses a thread to send out log messages

## 2015-04-21 `7833d98`

[Andrew Hodgkinson] The last few changes to test session handling have been experimental, but finally this commit settles it all down to something rational. Test coverage is much improved here, with the permissions spec in particular now really testing what it should be testing and with explicit "passes interaction ID along for inter-resource calls" tests (both local and remote) rather than implicit tests.

## 2015-04-16 `94e5b39`

[ckaye] Merge pull request #52 from LoyaltyNZ/feature/easier_dev_session_management

## 2015-04-16 `3ecc211`

[Andrew Pett] Merge pull request #51 from LoyaltyNZ/hotfix/improved_create_and_update_validation

## 2015-04-16 `3d5212c`

[Andrew Hodgkinson] Let developers do pure test session based development without Memcached implied interference for inter-resource calls

## 2015-04-16 `c4817bb`

[Andrew Hodgkinson] Restore Dockerised Travis builds since it doesn't affect DRb failure rate; enable Ruby / Bundler caching

## 2015-04-16 `2777998`

[Andrew Hodgkinson] Finish off test coverage

## 2015-04-16 `81c391f`

[Andrew Hodgkinson] Merge branch 'master' into hotfix/improved_create_and_update_validation

## 2015-04-16 `fa5e8ec`

[Andrew Hodgkinson] Experimental - bypass session augmentation in the specific edge case of using the out-of-box default test session (for very bare bones local development cross-resource)

## 2015-04-16 `bac5fa7`

[Andrew Hodgkinson] WIP probably non-functional, due to context switch :-/

## 2015-04-13 `cec8aaa`

[davidamitchell] Merge pull request #50 [proprietary change]

## 2015-04-13 `627b03c`

[Joseph Leniston] [Proprietary change]

## 2015-04-13 `b572589`

[Rory Stephenson] Merge pull request #48 from LoyaltyNZ/hotfix/duplicate_embed_or_reference

## 2015-04-13 `f60d153`

[Andrew Hodgkinson] Merge branch 'master' into hotfix/duplicate_embed_or_reference

## 2015-04-13 `f20736e`

[Andrew Hodgkinson] Filter out duplicates in _embed/_references query data

## 2015-04-10 `5aebb99`

[Rory Stephenson] Merge pull request #47 from LoyaltyNZ/feature/generic_identity

## 2015-04-09 `0eb7974`

[Andrew Hodgkinson] More comprehensive approach; test fixes

## 2015-04-09 `e93acf3`

[Andrew Hodgkinson] Bridge to support legacy log packet reception in service_logging

## 2015-04-09 `af4f08e`

[davidamitchell] Merge pull request #46 [proprietary change]

## 2015-04-09 `a859d8d`

[Joseph Leniston] Merge branch 'master' [proprietary change]

## 2015-04-08 `32c5b1f`

[Andrew Hodgkinson] Merge branch 'master' into feature/generic_identity

## 2015-04-08 `a3b3cf2`

[Andrew Hodgkinson] Merge pull request #44 from LoyaltyNZ/feature/generic_caller

## 2015-04-08 `dd36ecc`

[thelollies] Add rendering specs to Caller.

## 2015-04-08 `b72a653`

[Rory Stephenson] Merge pull request #45 from LoyaltyNZ/feature/improve_data_reference_dsl

## 2015-04-08 `b0e7a33`

[Andrew Hodgkinson] Merge branch 'experimental/fix_for_travis_drb_issues' into feature/improve_data_reference_dsl

## 2015-04-08 `374c5c0`

[Andrew Hodgkinson] Attempt 2

## 2015-04-08 `ecc29b2`

[Andrew Hodgkinson] Attempt 1

## 2015-04-08 `5b53ad8`

[Andrew Hodgkinson] Travis mallet insufficiently large

## 2015-04-08 `01e74b4`

[Andrew Hodgkinson] Hit Travis with a mallet

## 2015-04-08 `343baff`

[Andrew Hodgkinson] Allow classes as well as class names for type/resource references

## 2015-04-08 `040d513`

[Joseph Leniston] [Proprietary change]

## 2015-04-08 `80e29cd`

[thelollies] Update Caller resource spec and add some tests for scoping and identity values.

## 2015-04-08 `a3f99da`

[thelollies] Force presence of "resources" key in permissions resources type.

## 2015-04-07 `f5dd166`

[Andrew Hodgkinson] Attempt to start debugging a Travis-only test failure in DRb checks [multiple entries]

## 2015-04-07 `75fccea`

[Andrew Hodgkinson] Fix an issue where interaction IDs were not correctly passed down for local inter-resource calls, with test coverage to catch such regressions in future for both local and remote inter-resource calls.

## 2015-04-02 `435f7b4`

[thelollies] Nest resources inside permissions.

## 2015-04-02 `790f6a2`

[thelollies] Allow a hash containing anything for Caller identity and scoping.

## 2015-04-02 `f1a14c1`

[Andrew Hodgkinson] Merge remote-tracking branch 'origin' into feature/generic_identity

## 2015-04-02 `b5aec68`

[Andrew Hodgkinson] Merge pull request #42 [proprietary change]

## 2015-04-01 `bd53a9f`

[Joseph Leniston] [Proprietary change]

## 2015-04-01 `ffd0ab9`

[Andrew Hodgkinson] Updates related to removing deprecated interface

## 2015-04-01 `e6798b4`

[Andrew Hodgkinson] Remove deprecated accessor

## 2015-03-31 `8a9df74`

[thelollies] Starting to make Caller generic

## 2015-03-31 `23de2b3`

[Andrew Hodgkinson] Merge branch 'master' into feature/generic_identity

## 2015-03-30 `8556a7c`

[Andrew Hodgkinson] Start work on generic identity in logging, to get to generic Hoodoo. Has implications though for logging service and what would happen when a "new" packet arrived vs "old". Cannot be deployed yet.

## 2015-03-30 `1a58a1e`

[Andrew Hodgkinson] Merge pull request #41 [proprietary change]

## 2015-03-30 `ee278a7`

[Joseph Leniston] Revert accidental update to Gemfile.lock

## 2015-03-30 `dec8d58`

[Joseph Leniston] [Proprietary change]

## 2015-03-26 `29583a8`

[Andrew Hodgkinson] Canned RDoc data update

## 2015-03-26 `eeba4e4`

[Andrew Hodgkinson] Handle 'nil' better (for receiving outdated log packets).

## 2015-03-26 `95a78bb`

[Andrew Hodgkinson] Canned RDoc data update

## 2015-03-26 `649e6a0`

[Tom Dionysus] Merge pull request #40 from LoyaltyNZ/feature/store_queue_log_report_time

## 2015-03-26 `ee5ac17`

[Andrew Hodgkinson] Add (MessagePack-compatible, sigh) support for high resolution "log event reported at" timestamps into the logging messages sent onto the queue.

## 2015-03-24 `d4e9202`

[Andrew Hodgkinson] Allow error response logging under secure_log_for.

## 2015-03-24 `9a8d551`

[Andrew Hodgkinson] Improved test coverage.

## 2015-03-24 `b33d648`

[Andrew Hodgkinson] Get tests passing again; needs extra coverage

## 2015-03-24 `f815892`

[Andrew Hodgkinson] White space change

## 2015-03-24 `5608cf1`

[Andrew Hodgkinson] Merge pull request #39 from LoyaltyNZ/hotfix/service_announcments_for_queue

## 2015-03-24 `14e175c`

[Graham Jenson] added service announcment for queue

## 2015-03-23 `8781dd9`

[Andrew Hodgkinson] RDoc data update.

## 2015-03-23 `4e52a71`

[Andrew Hodgkinson] RDoc commentary fix.

## 2015-03-23 `03d5b91`

[ckaye] Merge pull request #38 from LoyaltyNZ/feature/add_errors_return_value

## 2015-03-23 `8bebc9b`

[davidamitchell] Merge pull request #37 from LoyaltyNZ/hotfix/defaults_for_create_or_update

## 2015-03-23 `69ac363`

[Andrew Hodgkinson] Make "#add_errors" (and by extension, Errors#merge!) return a more helpful value (with docs and tests).

## 2015-03-23 `ccd79bc`

[Andrew Hodgkinson] Fix issue #36.

## 2015-03-23 `564f5e3`

[Andrew Hodgkinson] Trivial white space change.

## 2015-03-19 `0aaf76a`

[Andrew Hodgkinson] White space changes

## 2015-03-18 `7d81c2a`

[Andrew Hodgkinson] The "sleep hack" in the DRb starter had prevented any subsequent "DRb server start" timeouts during tests on my local machine, but Travis still saw them. Given the mystery of the apparent 'fix', this is something of a relief; removed the pointless code and related lengthy comment.

## 2015-03-18 `7ceebb2`

[Andrew Hodgkinson] Bundle update

## 2015-03-18 `eceb39b`

[Andrew Hodgkinson] Canned RDoc data update

## 2015-03-18 `74dbb1f`

[Andrew Hodgkinson] Fix a test in light of an on-queue inter-resource call bug fix merged from PR a few minutes ago.

## 2015-03-18 `d77e882`

[Andrew Hodgkinson] Merge pull request #35 from LoyaltyNZ/hotfix/fix_query_for_inter_service_resource_calls

## 2015-03-18 `b0f013b`

[Rory Stephenson] Merge pull request #34 from LoyaltyNZ/feature/strip_unknown_fields

## 2015-03-18 `ff154d3`

[Graham Jenson] Fixes inter-service-resource-calls for amqp endpoint

## 2015-03-17 `c54fc0a`

[Andrew Hodgkinson] Full test coverage.

## 2015-03-17 `7962ed5`

[Andrew Hodgkinson] Merge remote-tracking branch 'origin' into feature/strip_unknown_fields

## 2015-03-17 `de65e02`

[Andrew Hodgkinson] Merge branch 'master' into feature/strip_unknown_fields

## 2015-03-17 `32c4087`

[Andrew Hodgkinson] Reject to-create/to-update fields which are not recognised. Test coverage TBA.

## 2015-03-17 `0374c03`

[Andrew Hodgkinson] Merge pull request #33 from LoyaltyNZ/feature/reference_rename

## 2015-03-17 `5827bcf`

[Andrew Hodgkinson] Move a per-request recomputed but unchanging Set into a constant.

## 2015-03-17 `e7cba0b`

[Andrew Hodgkinson] Fix an intermittent test failure by black magic. TODO noted because this shouldn't be necessary and I hate not understanding the exact cause. This is a very lazy commit.

## 2015-03-17 `1fc66df`

[David Mitchell] update enum

## 2015-03-16 `e641999`

[Andrew Hodgkinson] First attempt at a simple way of stripping unknown fields for POST or PATCH by rendering the body data through the presenter that is used to validate it. Needs more test coverage.

## 2015-03-16 `dde3740`

[David Mitchell] [Proprietary change]

## 2015-03-15 `21aaebe`

[Andrew Hodgkinson] Bundled RDoc data update.

## 2015-03-15 `6b31382`

[Andrew Hodgkinson] Documentation improvements.

## 2015-03-15 `4c28437`

[Andrew Hodgkinson] Merge pull request #32 from LoyaltyNZ/feature/client

## 2015-03-15 `070f035`

[Andrew Hodgkinson] Today's date, move "byebug" to a slightly more sensible location

## 2015-03-15 `4cb0b97`

[Andrew Hodgkinson] Full documentation coverage and some documentation updates.

## 2015-03-15 `cbbab6b`

[Andrew Hodgkinson] Bundle update

## 2015-03-13 `89d2d03`

[Andrew Hodgkinson] Start on documentation coverage and improvements.

## 2015-03-13 `f7edfc5`

[Andrew Hodgkinson] 100% passing useful test coverage achieved.

## 2015-03-13 `bb4a2bc`

[Andrew Hodgkinson] Inching towards 100% coverage

## 2015-03-13 `70867bb`

[Andrew Hodgkinson] More tests; API change in Client to take session ID, not session instance.

## 2015-03-13 `c652997`

[Andrew Hodgkinson] Start on Hoodoo::Client tests.

## 2015-03-12 `285a66f`

[David Mitchell] [Proprietary change]

## 2015-03-12 `2a4fc6c`

[Andrew Hodgkinson] Test fix.

## 2015-03-12 `5203b15`

[Andrew Hodgkinson] Help avoid "whack-a-mole" with query string parameter errors

## 2015-03-12 `abbe521`

[Andrew Hodgkinson] Client lives!

## 2015-03-12 `2d9890f`

[Andrew Hodgkinson] Further test coverage; Endpoint API change (store session ID not full session instance).

## 2015-03-12 `b1b3cd8`

[Andrew Hodgkinson] Merge remote-tracking branch 'origin/master' into feature/client

## 2015-03-12 `b2a6769`

[Andrew Hodgkinson] 100% passing non-trivial coverage on everything except the WIP that is (external-facing) Client itself.

## 2015-03-12 `8abd441`

[Andrew Hodgkinson] Merge pull request #31 [proprietary change]

## 2015-03-12 `06de931`

[Andrew Hodgkinson] Make it green. GREEN. *GREEN*, I TELL YOU.

## 2015-03-11 `9f898c6`

[Andrew Hodgkinson] Only 3 tests left...

## 2015-03-11 `2c35381`

[Andrew Hodgkinson] More tests passing.

## 2015-03-11 `4448e64`

[David Mitchell] [Proprietary change]

## 2015-03-11 `3ddde67`

[Andrew Hodgkinson] Much improved test performance, but still lots more to do.

## 2015-03-11 `c04ec81`

[Andrew Hodgkinson] More test fixes; bring in 'byebug' for when things get *really* nasty; bundle update.

## 2015-03-10 `2c1ac9b`

[Andrew Hodgkinson] Start work on test code

## 2015-03-10 `2a14d31`

[Andrew Hodgkinson] Move a few files around. Add requirements for all new files, fixing syntax errors revealed by that.

## 2015-03-10 `9643d89`

[Andrew Hodgkinson] Continued non-functional WIP; checking in as a backup.

## 2015-03-10 `5e78eba`

[Joseph Leniston] Merge pull request #30 [proprietary change]

## 2015-03-09 `e8bc3ee`

[Andrew Hodgkinson] Merge branch 'master' into feature/client

## 2015-03-09 `5e9a68f`

[Andrew Hodgkinson] Some test refactoring to avoid a test-environment conditional in the middleware which led indirectly to a recent failure to launch 'racksh' and make a previously very brittle test more robust.

## 2015-03-09 `6145e91`

[Andrew Hodgkinson] Merge branch 'master' into feature/client

## 2015-03-09 `504df69`

[Rory Stephenson] Merge pull request #29 from LoyaltyNZ/hotfix/racksh

## 2015-03-09 `3e592f0`

[Andrew Hodgkinson] That'll teach me to try and be thorough :-/

## 2015-03-09 `7ab3f36`

[Andrew Hodgkinson] Fix 'racksh' off-queue error from DRb registration arising from missing host/port.

## 2015-03-09 `f162cea`

[Andrew Hodgkinson] More WIP

## 2015-03-09 `4d37a01`

[Andrew Hodgkinson] Ongoing non-functional WIP

## 2015-03-08 `497f89f`

[Andrew Hodgkinson] Ongoing completely non-functional WIP.

## 2015-03-06 `5f9ec57`

[David Mitchell] [Proprietary change]

## 2015-03-06 `dc78225`

[Andrew Hodgkinson] Completely non-functional WIP

## 2015-03-05 `4f8e7e0`

[Andrew Hodgkinson] Move "Hoodoo::Services::Discovery::Base" to "Hoodoo::Services::Discovery" as the pattern causes a proliferation of "base.rb" files and pointless one-level-down module namespaces that may as well be the actual base class.

## 2015-03-05 `8cf8be2`

[Andrew Hodgkinson] Merge branch 'master' of https://github.com/LoyaltyNZ/hoodoo

## 2015-03-05 `d35f772`

[Andrew Hodgkinson] Stop DRb spawning lots of unnecessary threads

## 2015-03-05 `51aba5a`

[Andrew Hodgkinson] Merge pull request #27 [proprietary change]

## 2015-03-05 `81f6e62`

[thelollies] [Proprietary change]

## 2015-03-04 `8c29c27`

[Andrew Hodgkinson] Small typing error change to fix test failure only seen on Ruby 2.2.0.

## 2015-03-04 `7ef3225`

[Andrew Hodgkinson] Add TODO comment warning about a potential external use of a private method.

## 2015-03-03 `af66321`

[Andrew Hodgkinson] Merge pull request #26 from LoyaltyNZ/feature/discovery

## 2015-03-03 `772942d`

[Andrew Hodgkinson] Merge branch 'master' into feature/discovery

## 2015-03-03 `6729103`

[Andrew Hodgkinson] Non-functional WIP.

## 2015-03-03 `47df2b1`

[Andrew Hodgkinson] Update canned RDoc data.

## 2015-03-03 `b1ab8b6`

[Andrew Hodgkinson] Doc fixes.

## 2015-03-03 `f48ee2a`

[Andrew Hodgkinson] Documentation for new classes.

## 2015-03-03 `94b4d9a`

[Graham Jenson] fixing pluralisation of resource, I am also trying to up my commits by making one character changes per commit

## 2015-03-03 `7010e37`

[Andrew Hodgkinson] Merge pull request #25 [proprietary change]

## 2015-03-03 `40ff85e`

[Graham Jenson] fixing up alignment

## 2015-03-03 `6cfb7e7`

[Graham Jenson] [Proprietary change]

## 2015-03-03 `5a6bf75`

[Andrew Hodgkinson] Merge remote-tracking branch 'origin/master' into feature/discovery

## 2015-03-03 `c4dd038`

[Andrew Hodgkinson] 100% test coverage (with some fixes in tests and code to pass).

## 2015-03-03 `74386c2`

[Andrew Hodgkinson] Merge pull request #23 [proprietary change]

## 2015-03-03 `635dbab`

[thelollies] [Proprietary change]

## 2015-03-03 `84801a2`

[Tom Dionysus] Merge pull request #24 [proprietary change]

## 2015-03-03 `0691cd5`

[David Mitchell] [Proprietary change]

## 2015-03-03 `963e125`

[Andrew Hodgkinson] Tests pass.

## 2015-03-03 `036d7b5`

[thelollies] [Proprietary change]

## 2015-03-03 `29b0e98`

[Andrew Hodgkinson] Further test fixes. Still some more to do here.

## 2015-03-02 `4665129`

[Andrew Hodgkinson] Some better test performance but still has lots of issues, especially depending upon run order (since discovery code is still extremely buggy).

## 2015-03-02 `acac78e`

[Andrew Hodgkinson] Non-functional WIP; checking in to pick up at home.

## 2015-03-02 `3258b1f`

[Andrew Hodgkinson] Explicitly require 'benchmark'

## 2015-03-02 `e92b79a`

[Andrew Hodgkinson] Top-level namespace for Benchmark

## 2015-03-02 `5fffa74`

[Andrew Hodgkinson] Use test session in development if there's no Memcache / session ID provided.

## 2015-02-27 `cf216c1`

[Andrew Hodgkinson] Totally unfinished, completely non-functional WIP being committed in case I get a chance to work on it this weekend.

## 2015-02-27 `b370f04`

[Andrew Hodgkinson] Fix a test

## 2015-02-27 `9d0cf9d`

[Andrew Hodgkinson] Improved test coverage for on-queue operations and better inter-resource call error handling.

## 2015-02-27 `e4e6cfc`

[Graham Jenson] Merge pull request #22 from LoyaltyNZ/hotfix/ircs_on_queue

## 2015-02-26 `fbf2d72`

[Graham Jenson] fixing spec

## 2015-02-26 `5048c73`

[Graham Jenson] Merge branch 'master' into hotfix/ircs_on_queue

## 2015-02-26 `4e4caee`

[Andrew Hodgkinson] Fix inter-resource calls on Alchemy (there's no non-mocked test coverage).

## 2015-02-26 `2c93ddc`

[Rory Stephenson] Merge pull request #21 from LoyaltyNZ/hotfix/secure_logging

## 2015-02-26 `485b851`

[Andrew Hodgkinson] White space / comment fixes.

## 2015-02-26 `aba3eda`

[Andrew Hodgkinson] 100% coverage

## 2015-02-26 `70cac01`

[Andrew Hodgkinson] Test coverage.

## 2015-02-26 `5a8f10b`

[Andrew Hodgkinson] First passes-tests (but has no explicit test coverage!) piece of work on secure logging.

## 2015-02-26 `4f55099`

[Andrew Hodgkinson] Merge pull request #20 from LoyaltyNZ/hotfix/acquire_within_join_chains

## 2015-02-26 `f742c15`

[Andrew Hodgkinson] From Joseph - use of field name alone can be ambiguous, so change to "table_name"."field_name".

## 2015-02-25 `6dcc56f`

[Andrew Hodgkinson] White space changes and documentation fixes

## 2015-02-25 `4c81a9b`

[Andrew Hodgkinson] Merge branch 'master' of https://github.com/LoyaltyNZ/hoodoo

## 2015-02-25 `34d8e03`

[Andrew Hodgkinson] Move from JSON.pretty_generate to JSON.generate for speed. We're now in a position where most debugging / API usage is done at a high enough level that "pretty printing" is handled at the client end.

## 2015-02-25 `91d30d4`

[davidamitchell] Merge pull request #18 [proprietary change]

## 2015-02-24 `ca9a8fd`

[Andrew Hodgkinson] Less stupid implementation of backwards-compatible polymorphic_find.

## 2015-02-24 `a8559b6`

[Andrew Hodgkinson] RDoc update.

## 2015-02-24 `deea555`

[Andrew Hodgkinson] Last piece of the 'return list count' puzzle.

## 2015-02-24 `f8684a8`

[Joseph Leniston] [Proprietary change]

## 2015-02-24 `e5d9df6`

[Andrew Hodgkinson] Submodule confusion fix part 2.

## 2015-02-24 `80a9506`

[Andrew Hodgkinson] Attempt to resolve weird module confusion in Git.

## 2015-02-24 `4888d91`

[Andrew Hodgkinson] Update Swagger generator.

## 2015-02-24 `854541b`

[Andrew Hodgkinson] Bundle update

## 2015-02-24 `2b85a90`

[Andrew Hodgkinson] RDoc data update.

## 2015-02-24 `229e45c`

[Andrew Hodgkinson] Merge pull request #17 from LoyaltyNZ/feature/automatic_scoping

## 2015-02-24 `488edd1`

[Andrew Hodgkinson] Comment updates to fix RDoc output issues.

## 2015-02-24 `2bac5d4`

[Andrew Hodgkinson] Full test coverage.

## 2015-02-24 `be5503e`

[Andrew Hodgkinson] Improved test coverage (more to come).

## 2015-02-24 `addd832`

[Andrew Hodgkinson] WIP initial commit, with test coverage ongoing - better API for the ActiveRecord Finder extensions and roll up the 'dataset count' concept in the changes too.

## 2015-02-23 `59b2f00`

[Andrew Hodgkinson] Merge pull request #16 [proprietary change]

## 2015-02-23 `1a29762`

[thelollies] [Proprietary change]

## 2015-02-19 `0740b16`

[Andrew Hodgkinson] Resolve a naming issue of client-vs-caller post-new Session stuff.

## 2015-02-19 `9749124`

[Andrew Hodgkinson] Nearly time to start building some Hoodoo Guides, I think...

## 2015-02-19 `34be674`

[Andrew Hodgkinson] Merge pull request #14 from LoyaltyNZ/hotfix/add_name_to_caller

## 2015-02-19 `2833a34`

[thelollies] Add name to Caller

## 2015-02-18 `f6c27ae`

[Andrew Hodgkinson] Enhanced testing of differing actions between resources locally and remotely confirms that permission addition behaviour in the middleware performs as expected. Hoodoo PR 13 arises from a misunderstanding.

## 2015-02-18 `a9fac3e`

[Andrew Hodgkinson] Merge pull request #13 from LoyaltyNZ/hotfix/different_action_for_downstream_call

## 2015-02-18 `ac04aff`

[David Mitchell] adding test which list clocks but show date/time

## 2015-02-18 `874d979`

[Andrew Hodgkinson] Don't try to log Exception objects, only strings - Exceptions can't be msgpack'd to the queue.

## 2015-02-18 `47ad22f`

[Andrew Hodgkinson] [Proprietary change]

## 2015-02-18 `be93d78`

[Andrew Hodgkinson] RDoc fix.

## 2015-02-18 `aead860`

[Andrew Hodgkinson] RDoc update.

## 2015-02-18 `161c0a8`

[Andrew Hodgkinson] Return to 100% test coverage.

## 2015-02-18 `03d402e`

[Andrew Hodgkinson] Empty hashes / missing default fallbacks lead to 'DENY' not 'nil'.

## 2015-02-17 `d9601b4`

[Andrew Hodgkinson] Improved test coverage

## 2015-02-17 `ec56abf`

[Andrew Hodgkinson] Merge pull request #11 from LoyaltyNZ/feature/nuclear

## 2015-02-17 `20667b2`

[Andrew Hodgkinson] RDoc update.

## 2015-02-17 `95b4a61`

[Andrew Hodgkinson] Imperfect but workable delete-interim-session code added to middleware.

## 2015-02-17 `1123782`

[Andrew Hodgkinson] Remove unused method.

## 2015-02-17 `5a1cdda`

[Andrew Hodgkinson] Allow the full test suite to pass in one go, when run as a single complete application in essence, through a combination of ensuring that service endpoints are universally unique across the entire test suite and addition of a 'flush the service registry' mechanism for the middleware_permissions_spec.rb case where duplicating the entire suite of services with variant names just for local-vs-remote test cases seemed silly.

## 2015-02-17 `b3bfff1`

[Andrew Hodgkinson] Merge branch 'feature/nuclear' of https://github.com/LoyaltyNZ/hoodoo into feature/nuclear

## 2015-02-17 `dff9f3f`

[Andrew Hodgkinson] Merge pull request #10 from LoyaltyNZ/hotfix/session_delete

## 2015-02-17 `abea245`

[thelollies] Add Session deleting

## 2015-02-17 `82100fe`

[thelollies] Fix Caller arrays which result in nil being rendered

## 2015-02-17 `8613c26`

[Andrew Hodgkinson] Make sure all resource names and paths across test suite are unique (except for some aspects of the middleware permissions tests, which need updating). The suite may start up all sorts of things in Threads, but that's still the same process, so the middleware's class variables (and for that matter, the associated DRb registry) will accumulate data as if it's all part of one giant platform installation.

## 2015-02-17 `e0323f9`

[Andrew Hodgkinson] Remove "set in class" family of methods; the approach didn't work.

## 2015-02-17 `ca525f1`

[Andrew Hodgkinson] Add #delete to MockDalliClient

## 2015-02-16 `4ac78cc`

[Andrew Hodgkinson] WIP to continue tomorrow.

## 2015-02-16 `72c8e8e`

[Andrew Hodgkinson] @@_env => @@environment

## 2015-02-16 `2981ea6`

[Andrew Hodgkinson] Add documentation for the Interaction class and update RDoc data.

## 2015-02-16 `ceca08c`

[Andrew Hodgkinson] Full test coverage on new permissions code, with a fair bit of refactoring to allow sessions to work with some amount of sanity. This will currently NEVER PASS AUTOMATED FULL TEST RUNS - the new tests must be run one at a time by hand to pass (!).

## 2015-02-16 `a5e3a0e`

[Andrew Hodgkinson] Local inter-resource call tests for permission granting added and pass.

## 2015-02-16 `36ea68a`

[Andrew Hodgkinson] Start on some extra tests.

## 2015-02-14 `3503017`

[Andrew Hodgkinson] Fix up various tests, so all pass; but no new coverage for new features, yet.

## 2015-02-14 `c3a711c`

[Andrew Hodgkinson] Add ability to externally update an arbitrary caller's version in Memcached.

## 2015-02-13 `845b9b6`

[Andrew Hodgkinson] Ongoing. Almost there...

## 2015-02-13 `d2bd954`

[Andrew Hodgkinson] ApiTools -> Hoodoo rename fallout: "An" => "A" / "an" => "a" (#3).

## 2015-02-13 `45eb0c6`

[Andrew Hodgkinson] ApiTools -> Hoodoo rename fallout: "An" => "A" / "an" => "a" (#2).

## 2015-02-13 `e43381e`

[Andrew Hodgkinson] ApiTools -> Hoodoo rename fallout: "An" => "A" / "an" => "a".

## 2015-02-12 `ce79601`

[Andrew Hodgkinson] Add a 'deep merge' mechanism (avoiding the need to pull in e.g. ActiveSupport for such things).

## 2015-02-10 `286f82b`

[Andrew Hodgkinson] RDoc data updated.

## 2015-02-10 `d23f4b1`

[Andrew Hodgkinson] Full permissions implementation including ASK, with a bug fix in Permissions and improved test coverage.

## 2015-02-10 `a4329ff`

[Andrew Hodgkinson] Rather weak work-around for RDoc's mystery failure to document constants (or indeed instance attributes/properties, were any defined) for the Middleware class (though it does so for analogous cases like Errors).

## 2015-02-10 `91f973e`

[Andrew Hodgkinson] RDoc data updated.

## 2015-02-10 `4c0e18d`

[Andrew Hodgkinson] Implement new session/permissions and testing mode in middleware, with updated test coverage. More test coverage coming soon, to make sure that permissions are being properly obeyed.

## 2015-02-09 `cf9fd96`

[Andrew Hodgkinson] Overlooked rename.

## 2015-02-09 `2862ad0`

[davidamitchell] Merge pull request #7 [proprietary change]

## 2015-02-09 `204f4d9`

[Joseph Leniston] [Proprietary change]

## 2015-02-09 `efa289d`

[Andrew Hodgkinson] Canned RDoc data updated.

## 2015-02-09 `b00b45b`

[Andrew Hodgkinson] Full test coverage on new Session code.

## 2015-02-09 `df7fd1c`

[davidamitchell] Merge pull request #3 [proprietary change]

## 2015-02-09 `f7f41b6`

[Joseph Leniston] merge

## 2015-02-09 `6b5d8c7`

[Andrew Hodgkinson] Merge pull request #6 [proprietary change]

## 2015-02-09 `b3055ed`

[David Mitchell] finish updating version

## 2015-02-09 `6c3b902`

[David Mitchell] do not update version number

## 2015-02-09 `256c2d7`

[David Mitchell] whitespace and rename client_id -> caller_reference

## 2015-02-09 `1dd10a3`

[Joseph Leniston] [Proprietary change]

## 2015-02-09 `d2c5038`

[David Mitchell] [Proprietary change]

## 2015-02-09 `7360341`

[David Mitchell] fix the data type of client_id

## 2015-02-09 `4b72fc7`

[David Mitchell] bump the version

## 2015-02-09 `8f8d650`

[David Mitchell] [Proprietary change]

## 2015-02-09 `46af12a`

[David Mitchell] [Proprietary change]

## 2015-02-09 `18c1dd4`

[David Mitchell] [Proprietary change]

## 2015-02-09 `b3da1be`

[David Mitchell] [Proprietary change]

## 2015-02-05 `f18fbd1`

[Andrew Hodgkinson] Lots of tweaks, code improvements / clarification etc. arising from new tests (WIP).

## 2015-02-05 `730f730`

[Andrew Hodgkinson] Bundle update

## 2015-02-05 `7cdc341`

[Andrew Hodgkinson] Last bit of renaming (URL -> host)

## 2015-02-05 `db054c9`

[Andrew Hodgkinson] RDoc update.

## 2015-02-05 `a6c0ff0`

[Andrew Hodgkinson] Rename 'memcache_url' variable to 'memcached_host', following previous commit.

## 2015-02-05 `aa0a2be`

[Andrew Hodgkinson] Allow MEMCACHED_HOST environment variable instead of just MEMCACHE_URL, since it's not a URL, and the service is called "Memcached" not "Memcache".

## 2015-02-05 `28d5854`

[Andrew Hodgkinson] Further Session interface changes. Unavoidably, have to tie in the notion of a Client UUID and Version at the top level so that we can invalidate Sessions easily through a Caller's lock_version value.

## 2015-02-04 `500fc7e`

[Andrew Hodgkinson] Add Session#expired?, with docs

## 2015-02-04 `b4b434c`

[Andrew Hodgkinson] Fix some docs issues; expose 'expires_at' in Session data and change the docs for that to a more achievable approach.

## 2015-02-04 `cfa43e3`

[Andrew Hodgkinson] Canned RDoc update.

## 2015-02-04 `86f2b1f`

[Andrew Hodgkinson] Capitalisation of 'memcached' for docs - settling on 'Memcached' (capital M), though http://memcached.org is inconsistent.

## 2015-02-04 `86e5729`

[Andrew Hodgkinson] Small API change. Session code is still theoretical (untested).

## 2015-02-04 `20db9a0`

[Andrew Hodgkinson] Updates to make everything use LegacySession (for now). Tests pass.

## 2015-02-04 `cc0c3e0`

[Andrew Hodgkinson] Bundle update

## 2015-02-04 `04988ea`

[Andrew Hodgkinson] Update legacy session class so it is explicitly named and documented as such.

## 2015-02-04 `59fb4a7`

[Andrew Hodgkinson] Rename spec to match renamed implementation.

## 2015-02-04 `b6383d8`

[Andrew Hodgkinson] Move session file to legacy session (rename only for now).

## 2015-02-04 `1966c5e`

[Andrew Hodgkinson] Add dependency.

## 2015-02-04 `6127a5d`

[Andrew Hodgkinson] Add gem which according to Dalli's documentation, will speed Dalli up by 20-30%.

## 2015-02-04 `a78a6d4`

[Andrew Hodgkinson] Make caller's lives easier by allowing symbols in input hashes to Permissions instances.

## 2015-02-04 `cf09d1d`

[Andrew Hodgkinson] Fix definition but for PermissionsDefaults type, with test coverage.

## 2015-02-04 `bd33075`

[Andrew Hodgkinson] Bit the bullet after the last checkin and decided to do a full-on "family rename" of the Permissions stuff. It's now all consistent [plus proprietary change notes].

## 2015-02-04 `614bfc8`

[Andrew Hodgkinson] This is a little unconventional, but I've renamed three Permissions type *files* just so that with filename based sorting, they end up grouped. It's a developer aid. Yes, this means the filename mismatches the class name somewhat.

## 2015-02-04 `2f04993`

[Andrew Hodgkinson] (Trivial) white space alteration

## 2015-02-03 `f3f5c8a`

[thelollies] Document default permissions as internal

## 2015-02-02 `7038ac7`

[Andrew Hodgkinson] Merge pull request #4 [proprietary change]

## 2015-02-02 `a67aee8`

[thelollies] [Proprietary change]

## 2015-02-02 `160c6b2`

[thelollies] Divide up resource_permissions and fix its structure.

## 2015-02-02 `c851418`

[Andrew Hodgkinson] Add #inspect to Errors class for easier use/debugging on e.g. the console.

## 2015-02-02 `dab4953`

[Joseph Leniston] [Proprietary change]

## 2015-02-02 `cc5c7ee`

[thelollies] Change expired_at to expires_at in Session schema

## 2015-02-02 `c11e797`

[thelollies] Use existing constants for actions/policies in resource_permissions.rb

## 2015-02-02 `d36a7b3`

[thelollies] Merge branch 'master' into [proprietary change]

## 2015-02-02 `9509e64`

[Andrew Hodgkinson] Rename constant to something more consistent/descriptive & update RDoc data.

## 2015-02-02 `53be6d7`

[Andrew Hodgkinson] Update canned RDoc data.

## 2015-02-02 `cf9be07`

[Andrew Hodgkinson] Add a constant listing known permissions values to aid resource definitions that rely upon these.

## 2015-02-02 `070f19d`

[thelollies] Add session/resource_permissions specs

## 2015-02-02 `186755e`

[Joseph Leniston] [Proprietary change]

## 2015-02-02 `1404449`

[Joseph Leniston] [Proprietary change]

## 2015-01-30 `0b71a8e`

[thelollies] Added caller, session resources. Added resource permissions type. Awaiting specs for session and resource permissions.

## 2015-01-29 `ff3c58f`

[Andrew Hodgkinson] Update canned RDoc data.

## 2015-01-29 `9c97c8a`

[Andrew Hodgkinson] Bring up to 100% non-trivial documentation coverage, including RDoc hiccup workaround

## 2015-01-29 `3f9e61b`

[Andrew Hodgkinson] Improve documentation coverage to 100% and move some docs around into more obvious/discoverable locations.

## 2015-01-28 `abdb99c`

[Andrew Hodgkinson] No longer need to exclude the now-removed 'legacy.rb' file.

## 2015-01-28 `1fb87ac`

[Andrew Hodgkinson] ApiTools migration script makes "legacy.rb" patch redundant.

## 2015-01-27 `9da7425`

[Andrew Hodgkinson] Document the 'Permissions' class.

## 2015-01-27 `724d345`

[Andrew Hodgkinson] Back to 100% test coverage (including the new, unused Permissions code).

## 2015-01-27 `81fc4b1`

[Andrew Hodgkinson] Update RDoc Rake task to ignore the "legacy.rb" file as this was polluting the documentation with unnecessary class references and confusing RDoc due to what amounted to aliases for class names. Resulting canned RDoc data update included.

## 2015-01-27 `674da99`

[Andrew Hodgkinson] Ruby 2.1.2 -> 2.1.5 in Travis configuration.

## 2015-01-27 `a886c7b`

[Andrew Hodgkinson] Tidying up the remaining outdated references.

## 2015-01-27 `9982ec4`

[Andrew Hodgkinson] Update canned RDoc data.

## 2015-01-27 `75251a2`

[Andrew Hodgkinson] Rename environment variables to use HOODOO prefix.

## 2015-01-27 `be1ec22`

[Andrew Hodgkinson] Merge pull request #1 from LoyaltyNZ/feature/hoodoo

## 2015-01-27 `b98f6b7`

[Andrew Hodgkinson] Über-rename of classes to better match folder structure and general sanity. Tests pass.

## 2015-01-26 `401dc0a`

[Andrew Hodgkinson] Fix a small error; now all tests pass.

## 2015-01-26 `08b5f8e`

[Andrew Hodgkinson] Add (currently hypothetical, in terms of current implementation) mapping from ApiTools to Hoodoo.

## 2015-01-26 `8524d26`

[Andrew Hodgkinson] Rename files in "spec" to match shuffled files in "lib".

## 2015-01-26 `c820739`

[Andrew Hodgkinson] Prefixes/tested versions of individual "includers".

## 2015-01-26 `b9a3cf7`

[Andrew Hodgkinson] Old habits die hard

## 2015-01-26 `3c43dde`

[Andrew Hodgkinson] Bundle update / "api_tools" -> "hoodoo" rename.

## 2015-01-26 `4ff8a9e`

[Andrew Hodgkinson] Rename 'api_tools' command line tool to 'hoodoo'.

## 2015-01-26 `46b4108`

[Andrew Hodgkinson] File/folder rename of "api_tools" to "hoodoo".

## 2015-01-26 `c09ea9e`

[Andrew Hodgkinson] Restructure inclusions (not tested).

## 2015-01-26 `92034c8`

[Andrew Hodgkinson] Add "::" prefix to clarify namespaces.

## 2015-01-26 `9372df8`

[Andrew Hodgkinson] White space and double to single quote change.

## 2015-01-26 `31aa1dc`

[Andrew Hodgkinson] The various internal Queue-related classes and the Ruby core classes have similar names; use the "::" prefix to make it absolutely clear what's what.

## 2015-01-26 `184c782`

[Andrew Hodgkinson] Last (for now) file reshuffle pass. Update api_tools.rb accordingly.

## 2015-01-26 `5802162`

[Andrew Hodgkinson] Fourth file reshuffle pass.

## 2015-01-26 `fe283fe`

[Andrew Hodgkinson] Third file reshuffle pass.

## 2015-01-26 `c4677ff`

[Andrew Hodgkinson] Second file reshuffle pass.

## 2015-01-26 `03f45fc`

[Andrew Hodgkinson] First file reshuffle pass.

## 2015-01-26 `7e9ce51`

[Andrew Hodgkinson] Search/replace "api_tools"/"apitools" -> "hoodoo", "ApiTools" -> "Hoodoo". This breaks everything because of now-incorrect filename references etc.

## 2015-01-23 `d444be3`

[Andrew Hodgkinson] Get back to 100% code coverage in service_middleware.rb.

## 2015-01-23 `d8069cd`

[Andrew Hodgkinson] Don't report exceptions in test/development modes (but otherwise do; and test for that implicitly).

## 2015-01-23 `6f8a0ed`

[Andrew Hodgkinson] The interaction ID field of an Errors resource cannot be mandatory due to historical data omitting it.

## 2015-01-23 `83cd92d`

[Andrew Hodgkinson] Start work on updated permissions system, with some file shuffling. Add interaction ID to error structures; this required a lot of internal changes to get the relevant details communicated through the stack and get tests working properly again.

## 2015-01-23 `68182c6`

[Andrew Hodgkinson] Require Ruby 2.1.5

## 2015-01-20 `b77454a`

[Andrew Hodgkinson] Change the style of debug logging and exit early to avoid string composition and object creation for debug-only log statements that Graham found were (potentially) slowing things down in all environments.

## 2015-01-20 `63c1715`

[Andrew Hodgkinson] Don't use instance variables when local variables or class variables will suffice.

## 2015-01-12 `e69e17f`

[Andrew Hodgkinson] Critical concurrency fix and experimental ActiveRecord API usage change.

## 2015-01-09 `2dfef6a`

[Andrew Hodgkinson] Update canned RDoc data

## 2015-01-09 `04c7859`

[Andrew Hodgkinson] Attempt another workaround with Travis

## 2015-01-09 `dc32ce6`

[Andrew Hodgkinson] Try to work around a Travis failure.

## 2015-01-08 `30e9920`

[Andrew Hodgkinson] Unknown log levels now logged to logentries.com as "unknown". Clarified spec wording.

## 2015-01-08 `45f9aba`

[Andrew Hodgkinson] Bring code coverage back up to 100% in light of pre-Christmas DRb changes.

## 2015-01-08 `de422bf`

[Andrew Hodgkinson] Merge branch 'master' of github.com:LoyaltyNZ/api_tools

## 2015-01-08 `b7745d4`

[Andrew Hodgkinson] Merge pull request #51 [proprietary change]

## 2015-01-08 `d91571b`

[David Mitchell] [Proprietary change]

## 2015-01-08 `03ea3de`

[Andrew Hodgkinson] Add logentries.com log writer, with test coverage. It isn't used by ApiTools by default.

## 2015-01-07 `573f325`

[Andrew Hodgkinson] Bundle update

## 2015-01-07 `4a66e50`

[Andrew Hodgkinson] Merge branch 'master' of github.com:LoyaltyNZ/api_tools

## 2015-01-07 `b45a42c`

[Andrew Hodgkinson] The "api_tools <service_name>" CLI command now replaces known service name strings in the shell with the given service name, reducing the amount of configuration/alteration required. Right now, that's just done via 'find' and 'sed'; perhaps in future the service shell might use a higher level template language for files which require substitution.

## 2014-12-24 `aed1f77`

[Andrew Hodgkinson] Bundle update (including ActiveRecord 4.2 / AREL 6).

## 2014-12-24 `7e2ec75`

[Andrew Hodgkinson] Docs tweak.

## 2014-12-24 `76ca417`

[Andrew Hodgkinson] Canned RDoc data updated.

## 2014-12-24 `3bae1e1`

[Andrew Hodgkinson] Markdown fix

## 2014-12-24 `df4109c`

[Andrew Hodgkinson] Merge branch 'master' of github.com:LoyaltyNZ/api_tools

## 2014-12-24 `4ffe583`

[Andrew Hodgkinson] Add some documentation on ApiTools environment variable usage.

## 2014-12-24 `d288b1e`

[Andrew Hodgkinson] Make test suite well behaved with respect to DRb daemon and provide a clean 'kill' interface. Fix intermittent test failure arising from not adding to DRb service if host/port are not discovered (via only setting the "fake" fallbacks in test mode).

## 2014-12-24 `9bc31fe`

[Andrew Hodgkinson] Merge pull request #50 from LoyaltyNZ/feature/adding_mutually_exclusive_error_plural

## 2014-12-24 `1829793`

[David Mitchell] field name -> names

## 2014-12-24 `cbb1d6d`

[Andrew Hodgkinson] Merge pull request #49 from LoyaltyNZ/feature/adding_mutually_exclusive_error

## 2014-12-24 `ffd54f5`

[David Mitchell] added mutually_exclusive error

## 2014-12-23 `9708d69`

[Andrew Hodgkinson] Don't show backtraces in production and Red (not UAT).

## 2014-12-23 `895df44`

[Andrew Hodgkinson] Remove debug output.

## 2014-12-23 `7bf7e7d`

[Andrew Hodgkinson] This is so cunning, you could pin a tail on it and call it a fox. Daemonised DRb for all.

## 2014-12-22 `07bd3d1`

[Andrew Hodgkinson] Adding in (temporarily) the Swagger generator so it's safely in GitHub over the holiday.

## 2014-12-22 `e3c2882`

[Andrew Hodgkinson] Trivial white space change (coding style)

## 2014-12-22 `a9c7973`

[Andrew Hodgkinson] RDoc fixes and canned data update.

## 2014-12-22 `a8df63a`

[Andrew Hodgkinson] Merge branch 'feature/instance_logging'

## 2014-12-22 `6a291ec`

[Andrew Hodgkinson] Merge branch 'master' into feature/instance_logging

## 2014-12-22 `85ff76b`

[Andrew Hodgkinson] Remove debug 'puts' from test.

## 2014-12-22 `d2d1a49`

[Andrew Hodgkinson] Don't set Alchemy class variable if inbound Rack data has no endpoint (this is really just to help with intermittent test failures around logging and the use of 'is @@alchemy defined' in the middleware).

## 2014-12-22 `ebd7790`

[Andrew Hodgkinson] Be more rigorous about preserving class state across tests (class variables are bad in the test context, but fast for real service code).

## 2014-12-22 `d4e9aa7`

[Andrew Hodgkinson] Update tests for higher accuracy times in flattened log output

## 2014-12-22 `d8a5991`

[Andrew Hodgkinson] Flattened output now reports time to 6 decimal places.

## 2014-12-22 `19fc0a5`

[Andrew Hodgkinson] Tricky refactor to sort out sensible use cases and account for unknown dependent service's log folder location.

## 2014-12-22 `66725cd`

[Andrew Hodgkinson] Remove redundant file.

## 2014-12-22 `ad2ee01`

[Andrew Hodgkinson] Test coverage to 100%.

## 2014-12-22 `5338fd7`

[Andrew Hodgkinson] All tests now pass

## 2014-12-22 `6a58c84`

[Andrew Hodgkinson] Update .gitignore in light of previous commit.

## 2014-12-22 `9b4fa3a`

[Andrew Hodgkinson] Move logs into 'log/...'.

## 2014-12-22 `3931211`

[Andrew Hodgkinson] Tiny code shuffle to clarify SSL-related code a bit.

## 2014-12-19 `c63cb49`

[Andrew Hodgkinson] Start fixing up tests post-refactor

## 2014-12-19 `45535e8`

[Andrew Hodgkinson] Merge pull request #45 from LoyaltyNZ/featurer/remove_external_currencies

## 2014-12-19 `8370492`

[David Mitchell] whitespacing

## 2014-12-19 `6cf7aff`

[Andrew Hodgkinson] Bundle update

## 2014-12-19 `26f493f`

[Andrew Hodgkinson] Remove some debugging output

## 2014-12-18 `8fbe169`

[Andrew Hodgkinson] More functional pool/logging work; lots of legacy logger API use to fix up still.

## 2014-12-18 `0b2af23`

[Andrew Hodgkinson] Fix subtle bug in endpoint reuse for HTTP inter-resource calls found by Andrew P, with test coverage that fails before the fix and passes now.

## 2014-12-18 `21a10c3`

[David Mitchell] removing external currency

## 2014-12-18 `e27504c`

[Andrew Hodgkinson] Faster Travis builds via allowing their infrastructure to use its Docker mechanism.

## 2014-12-17 `200c15c`

[Andrew Hodgkinson] Ongoing work in progress, still non functional.

## 2014-12-17 `7423628`

[Andrew Hodgkinson] NON FUNCTIONAL work in progress.

## 2014-12-16 `3d716e5`

[Andrew Hodgkinson] Shuffle some ExceptionReporting code around to make more sense; restructure Logging section as Logger, to eventually replace legacy class-based logger code.

## 2014-12-16 `b1f558f`

[Andrew Hodgkinson] Clarified fast/slow Communicator documentation via reference to Pool.

## 2014-12-16 `3d80a98`

[Andrew Hodgkinson] Canned RDoc update

## 2014-12-16 `b041001`

[Andrew Hodgkinson] Bundle update

## 2014-12-16 `3569bf1`

[Andrew Hodgkinson] Version bump to 0.6.0 to account for previous commit's bug fix and new API features.

## 2014-12-16 `478ddb7`

[Andrew Hodgkinson] New 'Communicators' mechanism. Exception reporting moved over to this. Logging will lean on it soon. Comprehensive tests. Test bug fix for public action interfaces which were "dirtying" the ApiTools::ServiceMiddleware class state, causing unexpected intermittent < 100% test coverage reports depending on seed. Important AR Finder bug fix related to incompatible field and ident data types.

## 2014-12-15 `0efe7c8`

[Andrew Pett] Merge pull request #44 [proprietary change]

## 2014-12-15 `fa801ee`

[David Mitchell] [Proprietary change]

## 2014-12-12 `1d3c7a1`

[Andrew Hodgkinson] More tests again; *so* close to 100% now.

## 2014-12-12 `874c506`

[Andrew Hodgkinson] More test coverage; very close to 100% now

## 2014-12-12 `34826ac`

[Andrew Hodgkinson] Nudge test coverage forward another inch...

## 2014-12-12 `8f3df8a`

[Andrew Hodgkinson] Full test coverage of recently merged additions to ApiTools.

## 2014-12-12 `071db38`

[davidamitchell] Merge pull request #43 from LoyaltyNZ/feature/new_model_and_irc_error_api

## 2014-12-12 `f848dea`

[Andrew Hodgkinson] Finish comments above 'TODO' implementation method and update name in accordance with other internal corrections ("service" -> "resource").

## 2014-12-11 `263d780`

[Andrew Hodgkinson] Breaking change - new errors API for AR models and inter-resource calling.

## 2014-12-10 `38844e4`

[Andrew Hodgkinson] Merge pull request #41 from LoyaltyNZ/feature/add_not_found

## 2014-12-10 `34b9f60`

[David Mitchell] removed for_rack return value

## 2014-12-10 `fb7e96c`

[David Mitchell] update of comments as result of PR comments

## 2014-12-10 `3528914`

[David Mitchell] adding the not_found method to the response, and tests

## 2014-12-09 `142c365`

[Andrew Hodgkinson] Fill in missing bits of CORS implementation, with test coverage.

## 2014-12-09 `1c2653e`

[Andrew Hodgkinson] Theoretical support for CORS / OPTIONS preflight in middleware.

## 2014-12-09 `411c16b`

[Andrew Hodgkinson] Rearrange thread/rescue code for exception monitoring; exceptions in threads wouldn't be properly caught before. Now catches and logs in-thread, reporting through the logger in a thread-safe manner using the global thread semaphore via "Thread.exclusive {}".

## 2014-12-09 `aee70ff`

[Andrew Hodgkinson] Comment update

## 2014-12-09 `51b4507`

[Andrew Hodgkinson] Various fixes for exception handling, with actual Raygun and Airbrake real service operation tested externally.

## 2014-12-09 `aaaa221`

[Andrew Hodgkinson] Resolve another dependency issue

## 2014-12-09 `4a7d61c`

[Andrew Hodgkinson] Tidy up some recent changes

## 2014-12-09 `1afa07e`

[Andrew Hodgkinson] Fix namespace issue

## 2014-12-09 `1308da3`

[Andrew Hodgkinson] Merge branch 'master' of github.com:LoyaltyNZ/api_tools

## 2014-12-09 `d4d7549`

[Andrew Hodgkinson] Convey Rack env through to error reporting engine

## 2014-12-09 `06b8817`

[Andrew Hodgkinson] Add exception reporting framework.

## 2014-12-09 `4d74467`

[David Mitchell] master merge

## 2014-12-08 `7687e5a`

[Andrew Hodgkinson] Update RDoc data.

## 2014-12-08 `3755177`

[Andrew Hodgkinson] Merge branch 'master' of github.com:LoyaltyNZ/api_tools

## 2014-12-08 `a0261a0`

[Andrew Hodgkinson] Finish implementation of public_actions in ServiceInterface DSL, with full test coverage including local service to service calls. Test coverage is now 100%, except for hard-coded temporary on-queue mappings and HTTPS transport inter-service remote calls.

## 2014-12-08 `da30f85`

[Andrew Hodgkinson] Merge pull request #40 [proprietary change]

## 2014-12-05 `1a68f67`

[Joseph Leniston] [Proprietary change]

## 2014-12-05 `247be72`

[Andrew Hodgkinson] Presenter layer enforces UTC output for created_at, per spec; tests updated where UTC was not being expected.

## 2014-12-05 `7e5e876`

[Andrew Hodgkinson] Extract enumeration values in types and resources to constants, so client code can use them.

## 2014-12-05 `2670c7b`

[David Mitchell] Added error raising if the response body is empty or nil

## 2014-12-05 `4541e66`

[Andrew Hodgkinson] Merge branch 'master' of github.com:LoyaltyNZ/api_tools

## 2014-12-05 `c83af5d`

[David Mitchell] http -> s

## 2014-12-05 `fd4ad9a`

[Andrew Hodgkinson] RDoc update

## 2014-12-05 `72fe085`

[davidamitchell] Merge pull request #39 from LoyaltyNZ/feature/api_changes_and_test_coverage

## 2014-12-05 `9551f77`

[David Mitchell] merge from master

## 2014-12-05 `8562c5f`

[David Mitchell] version bump

## 2014-12-05 `1b144a4`

[Andrew Hodgkinson] Correct outdated parameter name in RDoc comment.

## 2014-12-05 `98035d8`

[Andrew Hodgkinson] Add in net/https 'require'.

## 2014-12-05 `dbe42bf`

[Andrew Hodgkinson] Merge pull request #38 [proprietary change]

## 2014-12-04 `2c361cd`

[David Mitchell] updates from PR and version bump

## 2014-12-04 `bb9dfe9`

[Andrew Hodgkinson] API changes to clean up finder and list stuff. Finder test coverage.

## 2014-12-04 `6882040`

[davidamitchell] remove code for debugging

## 2014-12-04 `c1542d3`

[David Mitchell] master merge

## 2014-12-04 `4260f8e`

[David Mitchell] adding remote calls to services via a static mapping table

## 2014-12-04 `38f6e19`

[Andrew Hodgkinson] Previous commit forces version bump.

## 2014-12-04 `4cadf87`

[Andrew Hodgkinson] [Proprietary change]

## 2014-12-04 `62c970e`

[Andrew Hodgkinson] Improved test coverage.

## 2014-12-04 `fc93e16`

[Andrew Hodgkinson] (Trivial) comment formatting change

## 2014-12-04 `5d8b076`

[Andrew Hodgkinson] Improved test coverage

## 2014-12-04 `58e942c`

[Andrew Hodgkinson] Merge branch 'master' of github.com:LoyaltyNZ/api_tools

## 2014-12-04 `cce6d2f`

[Andrew Hodgkinson] Merge pull request #37 [proprietary change]

## 2014-12-04 `3963aab`

[Andrew Hodgkinson] Tidy up nasty "private class method" hole I dug myself into yesterday.

## 2014-12-04 `57b3d04`

[Andrew Hodgkinson] Fix intermittent order-dependent test failure.

## 2014-12-04 `e05e3cd`

[thelollies] Fix resource specs

## 2014-12-04 `6f66d33`

[Andrew Hodgkinson] Add "public_actions" to Interface DSL; sessions are not required for this.

## 2014-12-04 `8282ed8`

[Andrew Hodgkinson] Trivial white space change

## 2014-12-04 `bac3df9`

[Andrew Hodgkinson] Improved test coverage

## 2014-12-04 `ffb7db0`

[thelollies] Bundle

## 2014-12-04 `1dc0a03`

[thelollies] [Proprietary change]

## 2014-12-04 `8889a46`

[thelollies] [Proprietary change]

## 2014-12-04 `994f508`

[Andrew Hodgkinson] Merge pull request #36 [proprietary change]

## 2014-12-04 `9d54c6f`

[thelollies] [Proprietary change]

## 2014-12-03 `15329e1`

[Andrew Hodgkinson] Restore test coverage lost when a couple of babies got thrown out with DocumentedPresenter layer bathwater.

## 2014-12-03 `54ca6fb`

[Andrew Hodgkinson] Post presenter-layer-merge cleanup (part 1)

## 2014-12-03 `2d831ee`

[davidamitchell] Merge pull request #35 [proprietary change]

## 2014-12-03 `c854107`

[thelollies] Bundle

## 2014-12-03 `423e237`

[thelollies] Bump version

## 2014-12-03 `2db1734`

[thelollies] Change ApiTools::Data::DocumentedPresenter to ApiTools::Presenters::Base

## 2014-12-03 `cd0a87c`

[thelollies] [Proprietary change]

## 2014-12-03 `e463501`

[davidamitchell] Merge pull request #34 [proprietary change]

## 2014-12-03 `04d725c`

[thelollies] [Proprietary change]

## 2014-12-03 `3538ced`

[Andrew Hodgkinson] RDoc update

## 2014-12-03 `753398c`

[Andrew Hodgkinson] Try a different "prod ActiveRecord" workaround to prevent connection failures seen in inter-service local calls sometimes.

## 2014-12-03 `d1ead8b`

[Andrew Hodgkinson] Update README in light of recent presenter layer merging.

## 2014-12-03 `5e77148`

[Andrew Hodgkinson] Clean up gemspec to avoid "gem build" warnings, including specifying an MIT licence provisionally.

## 2014-12-02 `3da4777`

[Andrew Hodgkinson] RDoc update.

## 2014-12-02 `a01dd65`

[Andrew Hodgkinson] BREAKING CHANGE: Merge 'DocumentedPresenters' to 'Presenters' and deal with the consequences.

## 2014-12-02 `38d436f`

[Andrew Hodgkinson] Merge pull request #33 from LoyaltyNZ/hotfix/memcache_serialization

## 2014-12-02 `e151744`

[Tom Cully] Fixed Session double serialization problem

## 2014-12-02 `65f5eb1`

[Andrew Hodgkinson] [Proprietary change]

## 2014-12-02 `a64fa22`

[Andrew Hodgkinson] Overdue test randomisation. Some tests now fail with certain seeds.

## 2014-12-01 `3fb52b7`

[Andrew Hodgkinson] Fix bugs in mechanism used to detect set class variables.

## 2014-12-01 `148b8b1`

[Andrew Hodgkinson] Merge pull request #32 from LoyaltyNZ/feature/uuid_validator

## 2014-12-01 `0d14322`

[Andrew Hodgkinson] Update RDocs.

## 2014-12-01 `26134ed`

[Andrew Hodgkinson] [Proprietary change]

## 2014-12-01 `6f23f28`

[Andrew Hodgkinson] Add "client_id" to session data and explicitly logged fields.

## 2014-12-01 `2979580`

[Andrew Hodgkinson] (Trivial) white space / single quotes change.

## 2014-12-01 `a1d9b53`

[thelollies] Formatting

## 2014-12-01 `ac5f211`

[thelollies] Avoid multiple includes of finder

## 2014-11-28 `553e05d`

[Andrew Hodgkinson] [Proprietary change]

## 2014-11-28 `9a619dc`

[Andrew Hodgkinson] Correct an incorrect comment.

## 2014-11-28 `645b88e`

[Andrew Hodgkinson] [Proprietary change]

## 2014-11-27 `ab37ed0`

[thelollies] Documentation fix

## 2014-11-27 `a9d3965`

[thelollies] Move and comment abstract class declaration

## 2014-11-27 `9dac384`

[thelollies] Adjust spec to reflect new Validator mixin behaviour

## 2014-11-27 `668adbd`

[thelollies] Disable instantiation when included in Base, fix documentation, enforce unique and present uuid.

## 2014-11-27 `ca0367a`

[thelollies] ApiTools::ActiveRecord::Base now successfully mixes in all active_record mixins

## 2014-11-27 `9d6d2e2`

[thelollies] Add github creds for travis

## 2014-11-27 `292c460`

[thelollies] Merge branch 'master' into feature/uuid_validator

## 2014-11-27 `fa7512f`

[thelollies] Only load validation code if active_model is present

## 2014-11-26 `8178744`

[Andrew Hodgkinson] Clean up dependency resolution and conditional inclusion of Things based on the idiomatic pattern of "try and require something, bail if LoadError happens". Follow this route for testing AMQEndpoint related code "for real" - this requires a temporary Gemfile hack since gemspec files don't support ":git" specifiers.

## 2014-11-26 `2f833dd`

[thelollies] Merge branch 'master' into feature/uuid_validator

## 2014-11-26 `8a6fee0`

[Andrew Hodgkinson] Fix code for ApiTools::ActiveRecord::Base and include it.

## 2014-11-26 `f476b05`

[thelollies] Lazy load activemodel extensions

## 2014-11-26 `3e8257a`

[thelollies] Add activemodel

## 2014-11-26 `ea65f5d`

[thelollies] include new validator

## 2014-11-26 `78b7846`

[Andrew Hodgkinson] Avoid incorrect Content-Type in responses when inbound content type is invalid.

## 2014-11-26 `6fdb206`

[thelollies] Add UUID validator and use it to assign better error codes

## 2014-11-26 `c1b9705`

[Andrew Hodgkinson] To-Create/To-Update validation checks now performed by middleware, with tests. Improved implementation of the DSL side of it. Cleaned up a check for body data where there should be none. Added extra test to cover previously unchecked error path through request code. Change to "after" hooks; these are now called whether or not there's an error in the context object after it was dispatched - reliable calling is useful.

## 2014-11-26 `ea1880a`

[Andrew Hodgkinson] Doc update

## 2014-11-25 `ddd48a2`

[Andrew Hodgkinson] [Proprietary change]

## 2014-11-25 `0840e7c`

[Andrew Hodgkinson] Developer-tested fixes. No automated coverage yet.

## 2014-11-25 `cf95eab`

[Andrew Hodgkinson] Lots of documentation added to Finder.

## 2014-11-25 `9cc08b4`

[Andrew Hodgkinson] Lots of fixes to prototype 'Finder' code.

## 2014-11-25 `3c5a8e5`

[Andrew Hodgkinson] Include prototype 'finder' code.

## 2014-11-25 `9f5fbe2`

[Andrew Hodgkinson] Fix ActiveRecord reference and specs post-merge.

## 2014-11-25 `71f8002`

[Andrew Hodgkinson] Merge branch 'feature/active_record_mixins'

## 2014-11-25 `dd04c55`

[Andrew Hodgkinson] Merge branch 'master' into feature/active_record_mixins

## 2014-11-25 `23000a6`

[Andrew Hodgkinson] Add Base class which includes all AR mixins; add more comments.

## 2014-11-25 `7306a58`

[Andrew Hodgkinson] Highly experimental AR extensions. Subject to change.

## 2014-11-25 `03b09bc`

[Andrew Hodgkinson] Update RDoc data

## 2014-11-25 `853bc77`

[Andrew Hodgkinson] [Proprietary change plus] Modifications to exception-in-exception-handler Rack usage as BodyProxy wasn't behaving properly. Version tests were in 'errors_spec.rb' and vice versa (!) so swapped.

## 2014-11-25 `6a2377a`

[Andrew Hodgkinson] Restore full (ish) logging of inbound request data. This has to be done manually and Rack doesn't make it easy.

## 2014-11-24 `2914687`

[Andrew Hodgkinson] Add in (slightly dodgy, much mocking!) test coverage for new logging stuff to at least get to 100% executed code coverage. Fixes up some state restoration problems with logging in passing.

## 2014-11-24 `fb66309`

[Andrew Hodgkinson] Logging fix - correct extraction of interaction ID.

## 2014-11-24 `40f8d52`

[Andrew Hodgkinson] [Proprietary change]

## 2014-11-24 `e5cce96`

[Andrew Hodgkinson] Tweak to logger STDOUT output in with-Alchemy case to be more useful for debugging and not spam console.

## 2014-11-24 `41a9d0a`

[Andrew Hodgkinson] Add in "platform.timeout" error. Set log level to ":info" unless in dev/test [plus proprietary change]

## 2014-11-24 `8dd610d`

[Andrew Hodgkinson] Temporarily remove logging of Rack environment as serialisation of this breaks MsgPack and prevents structured logging from working. Optionally take the logging queue name from an environment variable.

## 2014-11-21 `9cfc261`

[Andrew Hodgkinson] Don't structured-log a message with the same UUID twice

## 2014-11-21 `df8e286`

[Andrew Hodgkinson] Make sure error payloads are sent through properly in #auto_log.

## 2014-11-21 `6e0d0e6`

[Andrew Hodgkinson] It isn't an endpoint, it's alchemy...

## 2014-11-21 `33b0532`

[Andrew Hodgkinson] Docs update

## 2014-11-21 `0645357`

[Andrew Hodgkinson] Code and test changes, including bug fixes; tests now pass.

## 2014-11-21 `83a7910`

[Andrew Hodgkinson] Typo fix

## 2014-11-21 `96ee1d4`

[Andrew Hodgkinson] Use the queue endpoint to send message instances.

## 2014-11-21 `72b582c`

[Andrew Hodgkinson] Wire up Alchemy to the structured logger.

## 2014-11-21 `fd74964`

[Andrew Hodgkinson] Add in service data to logged errors. Fill in AMQPLogMessage body (based on logging service implementation).

## 2014-11-20 `fa072ac`

[Andrew Hodgkinson] Partial rewrite of ApiTools::Logger to support structured logging via ::report. Custom middleware logger which understands AMQEndpoint data if available (implementation forthcoming). No test coverage yet.

## 2014-11-19 `8e9e50a`

[Joseph Leniston] Merge pull request #31 [proprietary change]

## 2014-11-19 `a96598b`

[Andrew Hodgkinson] [Proprietary change]

## 2014-11-19 `c15380c`

[Andrew Hodgkinson] Merge pull request #30 [proprietary change]

## 2014-11-19 `1a8387d`

[Joseph Leniston] [Proprietary change]

## 2014-11-19 `c5618c8`

[Andrew Hodgkinson] On reflection, I think AR connection pool resets in test mode are *probably* harmless so will allow these to run in all environments. This fixes the build failure that Travis will have been reporting for the last couple of commits. It may need revisiting.

## 2014-11-19 `aeedf44`

[Andrew Hodgkinson] Use real UUIDs in the fake session data, so that any code using and storing this data in any context will not get validation failures around bad UUID formats.

## 2014-11-19 `9dd4f20`

[Andrew Hodgkinson] API update accounting for changes in ActiveRecord 3 -> 4.

## 2014-11-18 `81a8b50`

[Andrew Hodgkinson] If ActiveRecord is present, poke it to try and wake up connections before handling a request. Implementation revealed a failure to call before/after callbacks during inter-service calls, hence extensive test modifications to check that local and remote calls work properly with or without callbacks defined (via using RSpec's expectations to create the methods via mocks).

## 2014-11-18 `5645b58`

[Andrew Hodgkinson] Merge pull request #29 [proprietary change]

## 2014-11-18 `bd1632d`

[David Mitchell] test fixing

## 2014-11-18 `9468d16`

[David Mitchell] [Proprietary change]

## 2014-11-18 `5db3bde`

[David Mitchell] move back to version 0.3.0

## 2014-11-18 `721fca4`

[David Mitchell] [Proprietary change]

## 2014-11-18 `99d0bf1`

[David Mitchell] move back to version 0.3.0

## 2014-11-18 `9897ce3`

[David Mitchell] move back to version 0.3.0

## 2014-11-18 `736e496`

[David Mitchell] update to file name in comment

## 2014-11-18 `8d990f9`

[David Mitchell] [Proprietary change]

## 2014-11-18 `89f1f5c`

[David Mitchell] [Proprietary change]

## 2014-11-18 `571fc80`

[David Mitchell] [Proprietary change]

## 2014-11-18 `c0f7e8b`

[David Mitchell] update to file name in comment

## 2014-11-18 `154d219`

[David Mitchell] [Proprietary change]

## 2014-11-18 `fc1e9c6`

[David Mitchell] [Proprietary change]

## 2014-11-18 `b0d18a0`

[David Mitchell] [Proprietary change]

## 2014-11-18 `a6060d3`

[Andrew Hodgkinson] Do "bundle update" to keep Travis happy and track recent dependency versions.

## 2014-11-17 `89100d7`

[Andrew Hodgkinson] (Trivial test output fix) #store is actually #store!

## 2014-11-17 `ebd5cdb`

[Andrew Hodgkinson] Add pending test for ApiTools::Errors#store!, so that it doesn't get forgotten.

## 2014-11-17 `d4258d9`

[Andrew Hodgkinson] Grammar bad Yoda like is.

## 2014-11-17 `2bd16b2`

[Andrew Hodgkinson] Add full stop :-P

## 2014-11-17 `831a5ae`

[Andrew Hodgkinson] Make a start on ActiveRecord mixins, with tests.

## 2014-11-17 `b82f462`

[Andrew Hodgkinson] Doc fixes.

## 2014-11-17 `8a93747`

[Andrew Hodgkinson] Remove spurious ".rb" in "api_tools.rb" 'require' statements.

## 2014-11-17 `b69da76`

[Andrew Hodgkinson] Remove ThreadSafeHash. It's no longer used or necessary for ApiTools.

## 2014-11-17 `f069b79`

[Andrew Hodgkinson] Updated canned RDoc data.

## 2014-11-17 `8719830`

[Andrew Hodgkinson] Version bump, in light of enhanced NewRelic support. Services relying upon this will need this feature, in 0.3.0 or later.

## 2014-11-17 `5a56a36`

[Andrew Hodgkinson] Enhanced ApiTools::ServiceMiddleware support for NewRelic, which can now wrap service applications as well as the middleware itself.

## 2014-11-17 `7b4be66`

[Andrew Hodgkinson] Updated all documentation with SDoc template, instead of Darkfish theme RDoc.

## 2014-11-17 `83a40a6`

[Andrew Hodgkinson] Remove previous canned RDoc data. Change generator to SDoc, which produces much nicer results. Add in 'sdoc' gem dependency and update the bundle.

## 2014-11-14 `d5c4fdd`

[Andrew Hodgkinson] More doc tweaks.

## 2014-11-14 `fab9d17`

[Andrew Hodgkinson] Documentation fixes and a placeholder for ActiveRecord stuff coming Real Soon Now.

## 2014-11-14 `c2b00d9`

[Andrew Hodgkinson] Add URI escaping for IDs (technically unnecessary, but showed up in demo code).

## 2014-11-14 `d97ea10`

[Andrew Hodgkinson] Last bit of coverage (and additional comments).

## 2014-11-14 `6c2d5e6`

[Andrew Hodgkinson] Inching towards 100% test coverage on DRb related data. A few internal changes arising.

## 2014-11-14 `5ef6c4b`

[Andrew Hodgkinson] Add explicit DRb server coverage (for local development), with supporting addition in ApiTools::Utilities that's tested implicitly by the DRb tests.

## 2014-11-14 `8564fe6`

[Andrew Hodgkinson] Merge pull request #27 from LoyaltyNZ/feature/transaction_resource

## 2014-11-13 `45f9ed6`

[davidamitchell] updates to comments about the name transaction

## 2014-11-13 `12e618a`

[David Mitchell] adding the transaction resource

## 2014-11-13 `0070374`

[Andrew Hodgkinson] Since there is still non-trivial hand-written Markdown data in 'docs', make it official by mentioning it in README.md.

## 2014-11-13 `452763f`

[Andrew Hodgkinson] Remove docs/logger.md as improved RDoc data in ApiTools::Logger now covers everything it said and more, with less risk of getting out of date.

## 2014-11-13 `4283c59`

[Andrew Hodgkinson] Move presenter documentation up a level, rather than sitting in a redundant folder. This documentation is currently up to date.

## 2014-11-13 `fbeda8b`

[Andrew Hodgkinson] Remove outdated file which includes information that README.md already now covers.

## 2014-11-13 `6e96695`

[Andrew Hodgkinson] Remove hand-written docs which are so completely out of date that they're not even worth updating (the basic concepts have changed or been removed entirely). RDoc documentation is the replacement.

## 2014-11-13 `25f4218`

[Andrew Hodgkinson] README.md tweak and update of canned RDoc data.

## 2014-11-13 `0c81bac`

[Andrew Hodgkinson] Update README to work more elegantly with RDoc and be a more useful introduction to ApiTools classes.

## 2014-11-13 `5e12b3c`

[Andrew Hodgkinson] [Proprietary change]

## 2014-11-13 `fdc7a42`

[Andrew Hodgkinson] Update canned RDocs

## 2014-11-13 `1f6baea`

[davidamitchell] Merge pull request #26 from LoyaltyNZ/feature/non_nil_request_data

## 2014-11-13 `a626c2f`

[Joseph Leniston] Merge pull request #25 from LoyaltyNZ/feature/refactor_uuids

## 2014-11-13 `b51c745`

[Andrew Hodgkinson] To make life easier for service authors, have the search, filter, reference and embed data inside a ServiceRequest object default to an empty object or array rather than nil.

## 2014-11-13 `6e65edd`

[Andrew Hodgkinson] Improved test coverage for UUID refactor.

## 2014-11-13 `341804d`

[Andrew Hodgkinson] Refactor UUIDs to make better use of the UUIDTools gem facilities, document UUID methods in ApiTools and include out-of-the-box reasonably robust validation.

## 2014-11-12 `f2fd039`

[Andrew Hodgkinson] Merge branch 'feature/remove_mappings'

## 2014-11-12 `5594d6b`

[Andrew Hodgkinson] Merge branch 'master' into feature/remove_mappings

## 2014-11-12 `ebab333`

[Andrew Hodgkinson] Update documentation based on pull request comments.

## 2014-11-12 `63a7a51`

[davidamitchell] Merge pull request #24 from LoyaltyNZ/feature/multiple_comprised_of_calls

## 2014-11-12 `85f152b`

[Andrew Hodgkinson] Remove spurious newline.

## 2014-11-12 `14b87af`

[Andrew Hodgkinson] Allow (with tests) multiple calls to "comprised_of" to collect together the declared interfaces (and remove duplicates).

## 2014-11-12 `0123c39`

[Andrew Hodgkinson] Update Gemfile.lock with general bundle update and reference to 0.2.0 of 'this' gem.

## 2014-11-12 `1343f4c`

[Andrew Hodgkinson] Update version to 0.2.0 in light of presentation layer changes.

## 2014-11-12 `824fa2e`

[Andrew Hodgkinson] Update in-code comments / references in light of changes to presentation layer.

## 2014-11-12 `b1488ad`

[Andrew Hodgkinson] Update docs to describe updates to presenter layer.

## 2014-11-12 `440e372`

[Andrew Hodgkinson] Remove ':mapping' option in presenters, thus remove #parse and simplify validation/rendering. Rendering now is far more consistent. Tests updated. Documentation to follow.

## 2014-11-12 `c50ee2a`

[davidamitchell] Merge pull request #22 [proprietary change]

## 2014-11-12 `9f5d6fc`

[Joseph Leniston] [Proprietary change]

## 2014-11-11 `30b23f5`

[Tom Cully] Dalli compress: false

## 2014-11-11 `5abcc7b`

[Tom Cully] Dalli uses serializer: JSON

## 2014-11-11 `f39f7b5`

[Andrew Hodgkinson] Update base_presenter.md

## 2014-11-11 `242bba0`

[Andrew Hodgkinson] Update base_presenter.md

## 2014-11-11 `f32c4fe`

[Andrew Hodgkinson] Add comment to aid future maintainers.

## 2014-11-11 `e27823c`

[Andrew Hodgkinson] Merge branch 'master' of github.com:LoyaltyNZ/api_tools

## 2014-11-11 `a7165f4`

[Andrew Hodgkinson] Refactor - split service_middleware.rb into a number of smaller files. It'd be nice to break up ServiceMiddleware itself at some point as the class is becoming unwieldy, but functional units that could be usefully split into separate classes are not immediately obvious at present.

## 2014-11-10 `de62f06`

[Joseph Leniston] Merge pull request #21 [proprietary change]

## 2014-11-10 `05340e5`

[Andrew Hodgkinson] [Proprietary change]

## 2014-11-10 `f8e35da`

[Andrew Hodgkinson] Use defined constants for length constraints in tests.

## 2014-11-10 `80f396c`

[Andrew Hodgkinson] Curious newline change arising in Gemfile.lock after a "bundle update".

## 2014-11-10 `338a496`

[Andrew Hodgkinson] Merge pull request #20 from LoyaltyNZ/feature/documented_resource

## 2014-11-10 `c4c7993`

[Joseph Leniston] Update Gemfile.lock to get travis to pass

## 2014-11-10 `d653010`

[Andrew Hodgkinson] Update HTTP code in error descriptions to match docs (should've been 405 all the time, but was 422 by mistake).

## 2014-11-10 `d40cd2f`

[Joseph Leniston] Minor documentation changes from PR feedback

## 2014-11-10 `8aaee33`

[Andrew Hodgkinson] [Proprietary change]

## 2014-11-10 `a5186b5`

[Andrew Hodgkinson] Merge pull request #19 [proprietary change]

## 2014-11-10 `b43424e`

[Andrew Hodgkinson] Merge remote-tracking branch [proprietary change]

## 2014-11-10 `0d1b92b`

[Andrew Hodgkinson] Remove debug 'puts', as it isn't needed anymore.

## 2014-11-10 `45c3be3`

[David Mitchell] updates based on PR comments

## 2014-11-10 `eaf6281`

[Joseph Leniston] Add resource method to Documented DSL to allow referencing resources in interface definitions

## 2014-11-10 `0335377`

[Andrew Hodgkinson] Make an ill-advised monkey patch conditional (but still equally ill-advised) in response to an error seen with Sidekiq in production.

## 2014-11-07 `a52e652`

[Andrew Hodgkinson] Add test coverage for a few uncovered areas like "on_queue?" in middleware. Add "documented" equivalent of Hash, with tests. Overdue fix of comments documenting validator methods in the presenter layer as returning an array - they return an ApiTools::Errors instance now.

## 2014-11-07 `71013b5`

[David Mitchell] update to code style

## 2014-11-07 `3de322e`

[David Mitchell] bump to 0.1.1

## 2014-11-07 `ee61294`

[David Mitchell] updates to align with existing coding style

## 2014-11-07 `484ce05`

[David Mitchell] some more comments

## 2014-11-07 `334afdc`

[David Mitchell] [Proprietary change]

## 2014-11-07 `02e5004`

[Andrew Hodgkinson] [Proprietary change]

## 2014-11-07 `b0427de`

[David Mitchell] [Proprietary change]

## 2014-11-07 `918a634`

[Andrew Hodgkinson] Version bump due to API change

## 2014-11-07 `04bc89c`

[Andrew Hodgkinson] Test coverage for previous commit

## 2014-11-07 `d1dfb48`

[Andrew Hodgkinson] [Proprietary change]

## 2014-11-07 `2a2896e`

[Andrew Hodgkinson] Test coverage for "default" options key in hashes, with several fixes across presenter layer arising.

## 2014-11-06 `3c35883`

[Andrew Hodgkinson] Update RDoc data.

## 2014-11-06 `6c270a2`

[Andrew Hodgkinson] Add Hash data type to base presenters. Prints warning about requiring further tests during testing - work-in-progress. Need a Documented equivalent.

## 2014-11-06 `8d962a9`

[davidamitchell] Merge pull request #17 from LoyaltyNZ/feature/new_response_methods

## 2014-11-06 `d09e280`

[Andrew Hodgkinson] Add 'set_resource' and 'set_resources' aliases to 'body=' for ServiceResponse, along with 'add_errors' which merges in an external error collection.

## 2014-11-06 `22b846b`

[Andrew Hodgkinson] Add missing "::" prefix to various class names.

## 2014-11-06 `25f33d4`

[davidamitchell] Merge pull request #16 from LoyaltyNZ/feature/presenters_generate_proper_errors

## 2014-11-06 `b4387c7`

[Andrew Hodgkinson] Fix up a few more tests; correct what was meant to be a bug fix, but actually bypassed intentional nested validation in face of existing errors in the 'object' type.

## 2014-11-06 `80e0a53`

[Andrew Hodgkinson] Generate a proper ApiTools::Errors instance during presenter validation.

## 2014-11-06 `883073a`

[Andrew Hodgkinson] Update error descriptions. Extend ServiceRequest with "ident" property, with test coverage.

## 2014-11-05 `336c364`

[Andrew Hodgkinson] Improve UUID presenter error messages and fix UUID spec to expect "invalid_uuid" instead of "invalid_string", with updated message.

## 2014-11-05 `729de45`

[Andrew Hodgkinson] Use new constraint constants.

## 2014-11-05 `f415c44`

[Andrew Hodgkinson] Be consistent with symbol-vs-string use.

## 2014-11-05 `b388e03`

[Andrew Hodgkinson] Add constraint constants for lengths. They'll be used elsewhere in a future checkin. Could also be used at ActiveRecord levels for services backing up JSON into the DB.

## 2014-11-04 `a34858f`

[Andrew Hodgkinson] Merge pull request #15 [proprietary change]

## 2014-11-04 `3e7a2db`

[Joseph Leniston] [Proprietary change]

## 2014-11-04 `49abdef`

[Joseph Leniston] [Proprietary change]

## 2014-11-04 `91bc70f`

[Andrew Hodgkinson] Small improvements to test coverage. Now looks like 100% non-trivial coverage, though there are bound to be unanticipated edge cases hidden away in there.

## 2014-11-03 `a8e332d`

[Andrew Hodgkinson] Improved test coverage for inter-service calls. Now at 100% code coverage (though not necessarily all-lines-checked-for-correctness!) across ApiTools.

## 2014-11-03 `92e41b7`

[Andrew Hodgkinson] Inter-service calls should return arrays as arrays, not the top level "_data" object; implement this for remote inter-service calls and add test coverage. Local call test coverage TBD.

## 2014-11-03 `484288c`

[Andrew Hodgkinson] Bring logger coverage to 100%

## 2014-10-31 `f3130f1`

[Andrew Hodgkinson] Full suite of inter-service remote HTTP call types. Fixed failure to pass through locale.

## 2014-10-31 `d6ce998`

[Andrew Hodgkinson] Merge branch 'master' of github.com:LoyaltyNZ/api_tools

## 2014-10-31 `d285e3c`

[Andrew Hodgkinson] More robust detection of Rack host/port when running under Rack/HTTP locally. A couple of fixes and passing test coverage for an inter-service remote call.

## 2014-10-31 `29ce8d6`

[Tom Cully] Merge pull request #10 from LoyaltyNZ/feature/remove_amqp_client

## 2014-10-28 `09ed96b`

[Tom Cully] Removed AMQP Service layer - now in amq-endpoint gem - bumped version

## 2014-10-31 `38efc40`

[Andrew Hodgkinson] Merge pull request #13 from LoyaltyNZ/feature/queue_and_cache_detection

## 2014-10-31 `4dab88a`

[Andrew Hodgkinson] Merge branch 'master' of github.com:LoyaltyNZ/api_tools

## 2014-10-31 `eb033dc`

[Andrew Hodgkinson] Start work on tests that bring up a real HTTP server locally in a thread, then talk to it with Net::HTTP.

## 2014-10-31 `e034ec2`

[Andrew Hodgkinson] Merge pull request #14 [proprietary change]

## 2014-10-31 `5198980`

[Joseph Leniston] [Proprietary change]

## 2014-10-31 `8c955d2`

[Andrew Hodgkinson] Queue/cache detection and switching.

## 2014-10-31 `37ed131`

[Andrew Hodgkinson] Second half of previous commit (oops!) - see 65b48d6406c766d551f230bfaef9c9873486218a

## 2014-10-31 `65b48d6`

[Andrew Hodgkinson] Move Tags and UUID types from Documented layer to base Presenters layer, so they're more generic. Update all doc references etc. and tests.

## 2014-10-30 `1d2a8fe`

[Andrew Hodgkinson] Initial implementation of remote inter-service calls, using Net::HTTP directly rather than RestClient.

## 2014-10-30 `0d53acc`

[Andrew Hodgkinson] Bundle update to pull in RestClient from new APITools dependency.

## 2014-10-29 `35c4677`

[Joseph Leniston] Merge pull request #9 from LoyaltyNZ/feature/amqp_multithread_limit

## 2014-10-29 `9f410ab`

[Tom Cully] Merge pull request #11 [proprietary change]

## 2014-10-29 `94050c0`

[Joseph Leniston] [Proprietary change]

## 2014-10-28 `1981325`

[Tom Cully] Removed untestable/random number_of_processors

## 2014-10-23 `d8c1359`

[Tom Cully] Added Logger level filter

## 2014-10-20 `2edce97`

[Joseph Leniston] Merge pull request #8 from LoyaltyNZ/feature/before_after_service_implementation_hooks

## 2014-10-20 `317fd8a`

[Tom Cully] Revert irritating lint changes

## 2014-10-20 `c191258`

[Tom Cully] Added platform.forbidden 403 error

## 2014-10-20 `8ee4fdb`

[Tom Cully] Added optional before/after methods to ServiceImplementation calls

## 2014-10-20 `9d5a5ed`

[Joseph Leniston] Merge pull request #7 from LoyaltyNZ/feature/sessions

## 2014-10-20 `efba332`

[Tom Cully] Changes for role auth, more specs

## 2014-10-20 `7331398`

[Tom Cully] Specs test for specific errors

## 2014-10-20 `aa9c417`

[Tom Cully] Fixed Typo

## 2014-10-20 `337becb`

[Tom Cully] Fixed Travis Ruby Version

## 2014-10-16 `04fc90d`

[Tom Cully] Added spec coverage for session

## 2014-10-16 `fd09990`

[Tom Cully] Better Session testing mode

## 2014-10-16 `9b34941`

[Tom Cully] Initial Session code

## 2014-10-20 `f3f1cfa`

[Tom Cully] Merge pull request #6 from LoyaltyNZ/bugfix/specs

## 2014-10-20 `d1c046b`

[Tom Cully] Specify Ruby 2.1.2+

## 2014-10-20 `eaef752`

[Tom Cully] Equals not identity on Float check

## 2014-10-20 `feef268`

[Tom Cully] Merge pull request #3 [proprietary change]

## 2014-10-20 `a6dba76`

[Tom Cully] Merge pull request #4 from LoyaltyNZ/feature/amqp_multithread_coverage

## 2014-10-20 `e92caa0`

[Tom Cully] Merge pull request #5 [proprietary change]

## 2014-10-20 `d394317`

[Tom Cully] Merge pull request #2 from LoyaltyNZ/binary

## 2014-10-17 `f7c922e`

[Joseph Leniston] [Proprietary change]

## 2014-10-16 `fe36347`

[Tom Cully] Added more spec coverage

## 2014-10-14 `6010834`

[Joseph Leniston] [Proprietary change]

## 2014-10-10 `8170144`

[Andrew Hodgkinson] Sweeping changes resolving string versus symbol confusion and updates to RDocs. Various DSLs can still use symbols for describing interfaces, types and so-on, but data rendering and validations is all done with string keys. This is necessary since both JSON security on Ruby < 2.1 prohibits use of symbolisation of externally provided JSON data (since that allows third parties to create arbitrary symbols in the service memory space which never get garbage collected, opening up a DOS attack vector), and things like HStore JSON data recovered from PostgreSQL will use string keys even if the stored original Hash had symbols.

## 2014-10-10 `3c679da`

[Tom Cully] Corrected Multithread endpoint spec

## 2014-10-10 `d728313`

[Andrew Hodgkinson] Additional debug logging.

## 2014-10-10 `f4de6e3`

[Andrew Hodgkinson] ...take 2 on uninitialised variable warnings.

## 2014-10-10 `44e748a`

[Andrew Hodgkinson] Merge branch 'master' of github.com:LoyaltyNZ/api_tools

## 2014-10-10 `1d87c9d`

[Andrew Hodgkinson] Add support for global ":default" option in presenter DSL, with test coverage via Currency documented type/resource. Update those to match Preview 8 of API doc, with tests. Initialise a couple of instance variables that caused RSpec complaints if run with full warnings.

## 2014-10-10 `19fe51c`

[Andrew Hodgkinson] Enable RSpec coloured output for everyone.

## 2014-10-10 `ef61264`

[Andrew Hodgkinson] Remove duplicated 'test.log' entry in .gitignore.

## 2014-10-10 `b32340e`

[Tom Cully] Updated call for new Bunny version

## 2014-10-09 `2615411`

[Andrew Hodgkinson] UUID reference data field renamed to "ident" for generic.not_found.

## 2014-10-08 `ab13250`

[Andrew Hodgkinson] First cut at inter-service local calls with test coverage.

## 2014-10-08 `c661b38`

[Andrew Hodgkinson] Add custom exceptions for 'unknown error code' and 'missing reference data' cases to aid code that tries to map between different error domains, allowing it to catch the specific case of a missing (presumed autogenerated) code and default to something more generic.

## 2014-10-08 `a076c72`

[Andrew Hodgkinson] Add more errors code test coverage and a "merge!" method.

## 2014-10-07 `dbe801b`

[Andrew Hodgkinson] Work in progress, but fixes up various tests.

## 2014-10-07 `19400cb`

[Andrew Hodgkinson] Merge branch 'master' of github.com:LoyaltyNZ/api_tools

## 2014-10-07 `adb5310`

[Andrew Hodgkinson] Equivalent to previous checkin, but fixes array validation for non-schema array types.

## 2014-10-07 `4ce3251`

[Andrew Hodgkinson] Fix array rendering bug for non-schema array types.

## 2014-10-07 `1776bef`

[Jordan Carter] add api_tools binary

## 2014-10-07 `e116d7d`

[Andrew Hodgkinson] Add tests & small tweak to content type case insensitivity fix.

## 2014-10-07 `a365aaa`

[Tom Cully] Added start spec

## 2014-10-07 `cd6df02`

[Tom Cully] Addeed stop spec

## 2014-10-07 `d70e989`

[Andrew Hodgkinson] ...Take 2

## 2014-10-07 `b3aa0a2`

[Andrew Hodgkinson] Don't care about case of content-type data.

## 2014-10-07 `f80785f`

[Andrew Hodgkinson] Breaks specs! Work in progress, including logging that'll be helpful for Joseph.

## 2014-10-06 `b179236`

[Andrew Hodgkinson] Proper implementation, with tests, of vetting the query parameters differently for "list" vs other actions.

## 2014-10-07 `68e137d`

[Tom Cully] Added create_rx_thread spec

## 2014-10-07 `89cd9d6`

[Tom Cully] Added create_worker_thread spec

## 2014-10-07 `2cecc0d`

[Tom Cully] Updated request_spec for type

## 2014-10-07 `028220f`

[Tom Cully] Fixed initialize defaults in request/response classes, removed hardcoded response type for request create_response

## 2014-10-07 `5086af8`

[Tom Cully] AMQPMultithreadedEndpoint specs, Request/Response Types

## 2014-10-06 `b98b56d`

[Tom Cully] More specs for AMQPMultithreadedEndpoint

## 2014-10-06 `d2d8c83`

[Tom Cully] Stubbed specs for AMQPMultithreadedEndpoint

## 2014-10-06 `27b1d71`

[Tom Cully] Removed redundant BaseService and examples

## 2014-10-06 `d85e3b4`

[Tom Cully] Removed redundant BaseClient specs

## 2014-10-06 `efb6494`

[Tom Cully] Refactored specs for service/*

## 2014-10-06 `d68db1b`

[Tom Cully] Merge branch 'master' of github.com:LoyaltyNZ/api_tools

## 2014-10-06 `5ba5c05`

[Tom Cully] Refactoring Specs for AMQP messages/endpoint

## 2014-10-05 `0d01695`

[Andrew Hodgkinson] Backed out experiment - needs a proper fix (Presenters should use the real Errors collection; HashWithIndifferentAccess required; errors collections should be mergeable).

## 2014-10-05 `0a11bb4`

[Andrew Hodgkinson] Fix the fix!

## 2014-10-05 `7a2df4d`

[Andrew Hodgkinson] Fixes previous experiment a little

## 2014-10-05 `a0f729a`

[Andrew Hodgkinson] Experimental change that allows response errors to be set directly as a hash or array. This is a temporary bypass to support presenters returning error arrays directly.

## 2014-10-05 `e363185`

[Andrew Hodgkinson] ...previous check-in worked, so updated tests.

## 2014-10-05 `017caf3`

[Andrew Hodgkinson] More useful 500-within-500 message (experimental).

## 2014-10-05 `c73a87c`

[Andrew Hodgkinson] Add validation behaviour for documented types that covers resource common fields.

## 2014-10-03 `fb9731f`

[Andrew Hodgkinson] Fix middleware failure to correctly pass through body data in requests (with test).

## 2014-10-03 `3f35cc5`

[Andrew Hodgkinson] Rename 'payload' to 'body' in Request (to match Response) & make part of the middleware more robust (test failure on Ruby 1.9).

## 2014-10-03 `a6e0be0`

[Andrew Hodgkinson] Change to JSON.pretty_generate as it aids development - at least for now.

## 2014-10-03 `fa3c41a`

[Andrew Hodgkinson] Rename "response_body" in ServiceResponse to just "body" (since the 'context.response.body' idiom is more sane). Add Version resource and test.

## 2014-10-03 `2a473f3`

[Andrew Hodgkinson] Fix tests and bug.

## 2014-10-03 `da0e83c`

[Andrew Hodgkinson] Trying an alternative response approach (breaks ServiceResponse tests)

## 2014-10-03 `9f94067`

[Andrew Hodgkinson] Don't need to wrap Rack response body data in an array.

## 2014-10-03 `d6cb2bb`

[Andrew Hodgkinson] Fix a naming issue (enquire/inquire), get remaining test coverage on ServiceMiddleware sorted, a few fixes. Seem to now have 100% coverage on all new components. More work still to do in middleware to allow embeds and references in non-list calls.

## 2014-10-03 `3a554d5`

[Andrew Hodgkinson] Back out doc changes as they didn't help.

## 2014-10-03 `9d41389`

[Andrew Hodgkinson] Attempt to beat RDoc into some kind of sensible submission, with limited success.

## 2014-10-03 `35457a5`

[Andrew Hodgkinson] Further tests/fixes and a refactor that uses a ServiceContext object to wrap session, request and response data.

## 2014-10-03 `d4b163a`

[Andrew Hodgkinson] Full coverage of ServiceRequest and ServiceResponse.

## 2014-10-03 `f5631c5`

[Andrew Hodgkinson] Full coverage for ServiceApplication, ServiceInterface.

## 2014-10-02 `cf240a8`

[Andrew Hodgkinson] Documentation fix.

## 2014-10-02 `16abe48`

[Andrew Hodgkinson] Ever-improving code coverage for the middleware.

## 2014-10-02 `386ffca`

[Andrew Hodgkinson] Lots more tests, now with stderr redirected to a log file. Service middleware testing & fixes coming along well.

## 2014-10-02 `decf304`

[Andrew Hodgkinson] Full test coverage for Errors/ErrorDescriptions.

## 2014-10-02 `b3999f0`

[Andrew Hodgkinson] More tests, some fixes arising.

## 2014-10-02 `f894b43`

[Andrew Hodgkinson] Merge branch 'master' of github.com:LoyaltyNZ/api_tools

## 2014-10-02 `104e497`

[Andrew Hodgkinson] ...and that's exception handling working properly.

## 2014-10-02 `8f82f38`

[Andrew Hodgkinson] Very early beginnings of middleware tests (at an integration level).

## 2014-10-02 `2a9af6c`

[Andrew Hodgkinson] Update bundle; remove ByeBug from Gemfile since it requires Ruby >= 2 and gemspec says we support 1.9.2; add Rack::Test.

## 2014-10-01 `aca93d7`

[Andrew Hodgkinson] Ongoing tests - WIP

## 2014-09-30 `8ec5248`

[Tom Cully] Multithreaded Service Refactor

## 2014-09-30 `72f0ae5`

[Andrew Hodgkinson] Test coverage for the documented_*.rb family; some doc updates and tweaks.

## 2014-09-30 `2da0c13`

[Andrew Hodgkinson] Fix 'internationalised' read/write name collision via 'is_internationalised?' accessor. Bug revealed by new tests (included). Internationalisation now propagates all the way up the "tree".

## 2014-09-30 `5cbbae9`

[Andrew Hodgkinson] Add parser testing for arrays too.

## 2014-09-30 `3a274ca`

[Andrew Hodgkinson] Test coverage for rendering and validation of enum, text and array presentation types.

## 2014-09-30 `ea5eddc`

[Andrew Hodgkinson] Update bundle. Include 'byebug', a Ruby 2 compatible debugger, for development mode.

## 2014-09-30 `3cd979b`

[Andrew Hodgkinson] Mark failing tests as pending to make new test development easier (less output noise).

## 2014-09-30 `2913ff3`

[Andrew Hodgkinson] Documentation tweaks.

## 2014-09-30 `dc8e88a`

[Andrew Hodgkinson] All current presenter-related tests pass; now time to add new ones.

## 2014-09-30 `b772aad`

[Andrew Hodgkinson] That'll teach me to try to write code at 3am.

## 2014-09-30 `0e87dce`

[Andrew Hodgkinson] Tidied up rendering for Array types.

## 2014-09-29 `a2e7a89`

[Andrew Hodgkinson] Nasty code, but working code, to render structures including arrays. Next step - tidy it up.

## 2014-09-29 `ffa214b`

[Andrew Hodgkinson] Restructure type/presenters DSL stuff into mixins to solve various issues. Errors resource now *almost* renders properly, except the renderer doesn't know about arrays yet. Other aspects are far cleaner.

## 2014-09-29 `528ac53`

[Andrew Hodgkinson] Start hooking up rendering properly, with resource-specific extensions in DocumentedPresenter.

## 2014-09-26 `9e69eac`

[Andrew Hodgkinson] Fix an error arising from a misconception. Types and Resources are now defined in terms of *presenters*, not *kinds*, so DocumentedKind goes and DocumentedPresenter replaces it.

## 2014-09-26 `01a5d7e`

[Andrew Hodgkinson] Oops ;)

## 2014-09-26 `35b6af2`

[Andrew Hodgkinson] More WIP, tidying up error description stuff and filling in a lot of the blanks with query string parsing.

## 2014-09-26 `8f07fe0`

[Andrew Hodgkinson] Mostly documentation changes. Need to sort out some issues with service declarations of error descriptions (middleware ignores those currently, always constructing a response containing an errors collection that only knows about default codes).

## 2014-09-26 `4b806a0`

[Andrew Hodgkinson] Ongoing work extending docs, middleware, adding to_list DSL for interfaces etc.

## 2014-09-25 `40fddcb`

[Andrew Hodgkinson] Ongoing WIP; documentation improvements.

## 2014-09-25 `fa33cfe`

[Andrew Hodgkinson] Ongoing WIP...

## 2014-09-24 `eb2c3a3`

[Andrew Hodgkinson] [Proprietary change plus] Get started on generic top-level exception/500 handler.

## 2014-09-24 `0bfc93f`

[Andrew Hodgkinson] Ongoing WIP

## 2014-09-24 `81f2bf7`

[Andrew Hodgkinson] Implementing the service description DSL. Ongoing work in progress.

## 2014-09-24 `328103a`

[Andrew Hodgkinson] Everything's better with colour, Tom.

## 2014-09-23 `a7107ee`

[Andrew Hodgkinson] Since there are same-named resources and types such as Currency, move the documented kind classes down one level in namespace. Start to build out the service application / interface stuff.

## 2014-09-23 `e0e8b53`

[Andrew Hodgkinson] Working types DSL and declarations for several Types from the Platform API.

## 2014-09-22 `139debe`

[Andrew Hodgkinson] Very much a work in progress! Start adding in service middleware components, structured error handling and standard types with DSL. Committing just to make sure the code is backed up via GitHub.

## 2014-09-19 `f4dd6ee`

[Tom Cully] Added scheme to protocol encapsulation

## 2014-09-19 `5632243`

[Tom Cully] Major refactor to support Alchemy/Rails

## 2014-09-15 `709c54b`

[Tom Cully] partial refactor of examples

## 2014-09-15 `acc3fdf`

[Tom Cully] Major refactor for http/json messages

## 2014-09-10 `d42d49d`

[Tom Cully] Refactored for AMQP Endpoint, Request/Response Objects, Added Examples

## 2014-09-10 `c1f4f47`

[Tom Cully] Ruby verion 2.1.2, Request/Response Objects

## 2014-09-09 `fc2f4ee`

[Tom Cully] More spec coverage

## 2014-09-09 `f8d9b45`

[Tom Cully] Improved code coverage

## 2014-09-09 `59c4e69`

[Tom Cully] Refactored BaseClient and added spec

## 2014-09-09 `39e4c5f`

[Tom Cully] Updated docs, spec for presenter render/parse

## 2014-09-09 `80f2da2`

[Tom Cully] Added default mapping

## 2014-09-09 `2ced717`

[Tom Cully] Added missing Presenter parse spec

## 2014-09-09 `f477dee`

[Tom Cully] Removed specific render/parse mapping from presenter

## 2014-09-07 `ed5040c`

[Tom Cully] Added proto request and response objects, timeouts for client and service

## 2014-09-07 `1e7ce11`

[Tom Cully] Added UUID and ThreadSafeHash specs

## 2014-09-05 `54ed746`

[Tom Cully] BaseService and BaseClient initial - specs to follow

## 2014-09-04 `1acd471`

[Tom Cully] Added Travis build badge

## 2014-09-04 `9158be2`

[Tom Cully] Added Rakefile for Travis support, removed rack/test from spec_helper

## 2014-09-04 `dd513ee`

[Tom Cully] Travis CI: Accept no substitutes.

## 2014-09-01 `8df9838`

[Tom Cully] Added spec for datetime method

## 2014-09-01 `3916149`

[Tom Cully] Minor README/doc corrections

## 2014-09-01 `766a8ee`

[Tom Cully] Added more specs for JSON schema

## 2014-09-01 `80c5e60`

[Tom Cully] Corrected rdoc link

## 2014-09-01 `f0e2d28`

[Tom Cully] Added all missing rdoc in code

## 2014-09-01 `020dc45`

[Tom Cully] Added presenter type class rdoc

## 2014-09-01 `c76f0a7`

[Tom Cully] More rdoc for Presenter::Object files

## 2014-09-01 `e3bae01`

[Tom Cully] More rdoc for Presenter::Object

## 2014-09-01 `f99aedf`

[Tom Cully] Added rdoc code comments/docs

## 2014-09-01 `d560910`

[Tom Cully] Fixed Presenter docs formatting

## 2014-09-01 `b4786cb`

[Tom Cully] More Updated Docs

## 2014-09-01 `1e21879`

[Tom Cully] Fixed code indentation

## 2014-09-01 `b612771`

[Tom Cully] Updated Logger Spec

## 2014-09-01 `b303866`

[Tom Cully] Updated README docs

## 2014-09-01 `eb3e7c9`

[Tom Cully] Added rdoc, incomplete README documentation, added warn to ApiTools::Logger

## 2014-08-29 `6f23c69`

[Tom Cully] Added nested required errors in objects when parent object is nil

## 2014-08-29 `5427f0f`

[Tom Cully] Fixed validation errors when not required and nil

## 2014-08-29 `18e3f12`

[Tom Cully] Added nested required correction

## 2014-08-29 `ec18be0`

[Tom Cully] Standardized error messages

## 2014-08-29 `b9da895`

[Tom Cully] Initial Commit
