# Talis Ruby Client

[![Build Status](https://travis-ci.org/talis/talis_rb.svg?branch=master)](https://travis-ci.org/talis/talis_rb)
[![Dependency Status](https://dependencyci.com/github/talis/talis_rb/badge)](https://dependencyci.com/github/talis/talis_rb)

A ruby gem that provides interactions with Talis primitives.

## Ubuntu Prerequisites

    sudo apt-get install libgmp-dev

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'talis', github: talis/talis_rb
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install talis

## Usage

### Security Configuration

Many client operations require an OAuth token. 
In order to carry out these operations, configure the OAuth client:

    require 'talis/authentication'

    Talis::Authentication.client_id = 'client_id'
    Talis::Authentication.client_secret = 'client_secret'

See the code for each class for specific usage:
* `lib/talis/authentication/login.rb` For server-side login workflow.
* `lib/talis/authentication/token.rb` For OAuth token generation and validation.
* `lib/talis/hierarchy/node.rb` For managing hierarchies.
* `lib/talis/hierarchy/asset.rb` For managing hierarchy assets.
* `lib/talis/user.rb` For managing Talis users.
* `lib/talis/bibliography/work.rb` For querying works.
* `lib/talis/analytics.rb` For sending analytical data.

## Development

After checking out the repo, run `bin/setup` to install dependencies. 

Create a `.env` file in the project root and configure the following variables:

    PERSONA_TEST_HOST=http://persona
    PERSONA_OAUTH_CLIENT=<client ID>
    PERSONA_OAUTH_SECRET=<client secret>
    BLUEPRINT_TEST_HOST=http://blueprint
    ECHO_TEST_HOST=http://echo
    
    METATRON_TEST_HOST=<Metatron host>
    METATRON_BASE_PATH=<set this to /env_name/2 if not using production>
    METATRON_OAUTH_HOST=<Persona host the Metatron host uses>
    METATRON_OAUTH_CLIENT=<client ID associated with oauth host above>
    METATRON_OAUTH_SECRET=<client secret associated with oauth host above>
    TEST_USER_GUID=<The GUID of the Talis test user (test.tn@talis.com)>

    
Adjust the values according to the primitives you want to test against (local or remote).
If testing locally then make sure the host names are in `/etc/hosts`.

Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

This project enforces style and lint rules via [Rubocop](https://github.com/bbatsov/rubocop). Run `rake rubocop` to check for violations.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
