require 'talis/version'
require 'talis/errors'
require 'talis/extensions/object'
require 'talis/authentication'
require 'bundler/setup'
require 'httparty'
require 'json'

# Main entry point
module Talis
  # TODO: configure this
  PERSONA_HOST = 'https://users.talisaspire.com'.freeze

  class << self
    def new(opts = {})
      token = Talis::Authentication::Token.generate(opts)
      Talis::Authentication::Client.new(token, opts)
    end
  end
end
