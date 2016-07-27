Firstly, thank you for contributing! Please read our [Engineering Handbook]
(http://talis.github.io/) for some guidelines.

# Local Development

## Setup

    bundle install
    
Create a `.env` file and add the following:

    PERSONA_TEST_HOST=<your local persona host>
    PERSONA_OAUTH_CLIENT=<your local persona client ID (with su scope)>
    PERSONA_OAUTH_SECRET=<your local persona client secret (with su scope)>
    BLUEPRINT_TEST_HOST=<your local blueprint host>
    METATRON_TEST_HOST=<your local metatron host>
    METATRON_BASE_PATH=<if not a production env, use /development>

If these variables are not set, the production primitives are used.

## Running Tests

    bundle exec rspec
    
## Versioning

Please use [semantic versioning](http://semver.org/) and bump 
`lib/talis/version.rb` when submitting a pull request.
