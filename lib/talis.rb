require 'talis/version'
require 'talis/constants'
require 'talis/errors'
require 'talis/extensions/object'
require 'talis/resource'
require 'talis/authentication'
require 'talis/oauth_service'
require 'talis/analytics'
require 'talis/hierarchy'
require 'talis/feeds'
require 'talis/user'
require 'talis/bibliography'
require 'bundler/setup'
require 'httparty'
require 'json'

# Main entry point
module Talis
  class << self
    def new(opts = {})
      token = Talis::Authentication::Token.generate(opts)
      Talis::Authentication::Client.new(token, opts)
    end
  end
end
