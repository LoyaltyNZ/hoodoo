# Hoodoo

[![Build Status](https://magnum.travis-ci.com/LoyaltyNZ/hoodoo.svg?token=qenLSjTyBsExZFCraVut&branch=master)](https://magnum.travis-ci.com/LoyaltyNZ/hoodoo)

Simplify the implementation of services within an API-based software platform.

## Usage

Add the gem to your `Gemfile`:

    gem 'hoodoo', :git => 'git@github.com:LoyaltyNZ/hoodoo.git'

Require hoodoo when needed:

    require 'hoodoo'

Functionality includes:

* _Middleware:_ The heart of services; Rake-based service applications (think Sinatra, Grape, Rails...) -- Hoodoo::Services::Middleware; but start at Hoodoo::Services::Service and see also Hoodoo::Services::Interface, Hoodoo::Services::Implementation and related classes Hoodoo::Services::Request, Hoodoo::Services::Response, Hoodoo::Services::Session, Hoodoo::Services::Context
* _Generic Presenter Layer:_ Input and output validation and rendering -- Hoodoo::Presenters::Base, Hoodoo::Presenters::BaseDSL
* _Unified Error Helpers:_ Adds standard platform error capability to any API/class -- Hoodoo::ErrorDescriptions, Hoodoo::Errors
* _Unified Logger:_ A single logger for use with platform or local logs -- Hoodoo::Logger
* _Platform Sessions:_ Authentication of sessions, session context -- Hoodoo::Services::Session
* _Platform Events:_ Publishes Platform Events when running on a queue-based infrastructure -- Hoodoo::Events::PlatformEvent
* _ActiveRecord Assistance_: If using ActiveRecord (optional), provides support methods/mixins for models to help bridge the gap between API resources and persistence -- Hoodoo::ActiveRecord

Master documentation is through RDoc (see below).

## Workflow / branches

Development occurs on either `master` directly, or temporary `hotfix` or `feature` branches which are subsequently merged to `master`. This model is used because Gem versions, once Hoodoo is stored in a public Gem repository, will allow other software to decide what changes to import or ignore. The Gem version is not usually altered while Hoodoo stays within a private repository.

## Tests

Run the tests:

    bundle exec rake

...or...

    bundle exec rspec

## Documentation (RDoc)

The Hoodoo public API is documented through source code comments that are designed to produce non-trivially useful output, with examples and workflow indications, when RDoc turns them into HTML. See earlier for some pointers to classes of interest that will be linked to the relevant class documentation if you read all of this through the RDoc output.

If working on an installed copy of the gem through normal channels, you should be able to issue this command:

    gem server

...and browse to port 8808 on `localhost` to get an index of all gem documentation, including that for Hoodoo. Out of the box from GitHub, RDoc precompiled documentation is available but there is a risk it might be out of date. If working on development of the gem in a GitHub repository clone, you can generate or entirely regenerate RDoc files (re-RDoc) with:

    rake rerdoc

Some additional higher level hand written documentation may also be present as Markdown data inside the `docs` folder.
