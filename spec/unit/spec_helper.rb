require 'dotenv'
Dotenv.load

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'talis'
require 'webmock/rspec'

def client_id
  ENV['PERSONA_OAUTH_CLIENT']
end

def client_secret
  ENV['PERSONA_OAUTH_SECRET']
end
