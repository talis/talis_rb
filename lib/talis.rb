require "talis/version"
require 'talis/errors'
require 'talis/extensions/object'
require 'talis/authentication'
require 'bundler/setup'
require 'httparty'
require 'json'

module Talis

  PERSONA_HOST = "https://users.talisaspire.com"

  class << self
    def new(opts={})
      token = Talis::Authentication::Token.generate(opts)
      return Talis::Authentication::Client.new(token, opts)
    end
  end
end
