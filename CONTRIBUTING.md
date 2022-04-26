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

## RubyGems deployment
In order to make Hoodoo Gem accessible to other Loyalty projects that are depending on it, new releases, internal releases,
it is necessary to publish it in the central repository called RubyGems.

The artifact submission process itself is coded in our CICD, implemented using Travis CI scripts. This specify CICD step is able to authenticate and send
the new release without major difficulties, just following standard procedures. But the question that routinely needs some explanation and understanding
here's how to trigger this process, to make it start.

This trigger is based on the repository's refs, whenever a commit with a new tag is detected, the deploy step is triggered.

Below is a brief description of the steps to reach this stage, from the code change, until we have a new version published on the RubyGems website.

We imagine the scenario where we will increase the Hoodoo version, so this will be the recommended sequence of steps:

1. Update version file, `lib/hoodoo/version.rb`, increasing constants VERSION and DATE
2. Update Readme file itself, topic `Note`, to contain the expected upcoming version
3. Run the command `bundle install`. Doing so, Bundle will be updating the file `Gemfile.lock` with the upcoming version
4. Update the `CHANGELOG.md` file, to contain the upcoming version notes
5. Start a new feature branch
6. Commit changes
7. Create a Pull Request
8. Get approval for this Pull Request
9. Merge the Pull Request
10. Now comes the tricky part. Until now, wasn't asked to do any kind of tagging, which is ok. This step can be achieved using the proper GitHub UI, we just need to follow some very simple steps.
    1. Access Hoodoo's repository home page, `https://github.com/LoyaltyNZ/hoodoo`
    2. Then access the list of existent releases, clicking on `Releases` link (https://github.com/LoyaltyNZ/hoodoo/releases)
    3. Now we need to start a Draft, clicking on `Draft a new release`
    4. Type title and description
    5. Click on `Choose a tag`, and copy over the entry from the changelog. Please do not select any existent tag, they do belong to older releases.
    6. When all of this typing is done, click on the button `Publish release`
11. When all these steps are done, just watch the CI process doing it's job. You can follow the steps accessing this page `https://app.travis-ci.com/github/LoyaltyNZ/hoodoo/builds/`
12. When Travis CI finishes, then access `https://rubygems.org/gems/hoodoo` to see a new fresh release published.


## Guides

We try to maintain the Hoodoo Guides internally but this is a big effort. If you're sending in a PR which might impact upon them, it would be really great if you could include an indication of this in your pull request description. Better still, if possible send us a related pull request to the `LoyaltyNZ/hoodoo` `gh-pages` branch which includes the necessary alterations!
