require "talis/version"
require 'talis/errors'
require 'talis/authentication'

module Talis
  class << self
    def new(opts={})
      return Talis::Authentication::Client.new(opts)
    end
  end
end
