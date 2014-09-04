# api_tools

[![Build Status](https://magnum.travis-ci.com/LoyaltyNZ/api_tools.svg?token=qenLSjTyBsExZFCraVut&branch=master)](https://magnum.travis-ci.com/LoyaltyNZ/api_tools)

A gem for simplifying the implementation of Loyalty Platform services.

## Usage

Add the gem to your `gemspec`:

    gem 'api_tools', :git => 'git@github.com:LoyaltyNZ/api_tools.git'

Require api_tools when needed:

    require 'api_tools'

Functionality includes:

| Component             | Description                                                 |
|:----------------------|:------------------------------------------------------------|
| Sinatra Helpers       | A set of sinatra extensions/modules to simplify API generation  |
| Unified Error Helpers | Adds standard Platform error capability to any API/class    |
| Unified Logger        | A single logger for eventual use with Platform logs         |
| Presenter Layer       | A presenter framework including input validation            |

Please see:

* [Descriptive documentation](docs/usage.md)
* [rdoc documentation here](docs/rdoc/index.html).

## Development

### Roadmap

| Change                     | Description                                                 |
|:---------------------------|:------------------------------------------------------------|
| ApiTools::PlatformContext  | Change to use full `X-Session-ID` and Redis context.        |

### Specs

Run the specs:

    rspec

### rdoc

Regenerate rdoc:

    bundle exec rdoc --op docs/rdoc lib/
