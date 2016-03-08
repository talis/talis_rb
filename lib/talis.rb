require "talis/version"
require 'talis/errors'
require 'talis/extensions/object'
require 'talis/authentication'
require 'bundler/setup'

module Talis
  class << self
    def new(opts={})
      return Talis::Authentication::Client.new(opts)
    end
  end
end
