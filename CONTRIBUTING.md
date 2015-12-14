# Contributions

We love getting pull requests for new features or fixes!

## Requirements

* Before you open a ticket or send a pull request, search for previous discussions about the same feature or issue. Add to the earlier ticket if you find one.
* Please follow the prevailing coding style, strange though it might seem, when making changes.
* Contributions can't be accepted without tests or necessary documentation updates. Run `bundle exec rspec` then see the coverage report in `coverage`; issue `bundle exec rake rerdoc` to re-generate RDoc data to check your coverage if you've added any new methods. Both must report 100%. Make changes to the Hoodoo API Specification document if required.
* When submitting a pull request, the more detail you can provide in the pull request body, the better. It helps us understand your intentions and more efficiently and accurately review the pull request.

## Workflow

* Fork the project and clone your fork as your local working copy (`git clone git@github.com:[username]/hoodoo.git`).
* Create a topic branch to contain your change (`git checkout -b feature/[description]` or `git checkout -b hotfix/[description]`).
* Make changes and ensure there's still full test and documentation coverage (`bundle exec rspec`, `bundle exec rake rerdoc`).
* If necessary, rebase your commits into logical chunks, without errors.
* Push the branch up (`git push origin feature/[description]`).
* Create a pull request against `LoyaltyNZ/hoodoo` `master` branch describing what your change does and the why you think it should be merged.

## Guides

We try to maintain the Hoodoo Guides internally but this is a big effort. If you're sending in a PR which might impact upon them, it would be really great if you could include an indication of this in your pull request description. Better still, if possible send us a related pull request to the `LoyaltyNZ/hoodoo` `gh-pages` branch which includes the necessary alterations!
