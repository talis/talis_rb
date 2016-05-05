require 'talis/version'
require 'talis/constants'
require 'talis/errors'
require 'talis/extensions/object'
require 'talis/resource'
require 'talis/authentication'
require 'talis/hierarchy'
require 'talis/event'
require 'talis/feed'
require 'talis/user'
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
