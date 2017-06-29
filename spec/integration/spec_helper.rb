require 'dotenv'
Dotenv.load

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'talis'
require 'webmock/rspec'
require 'rspec/wait'

WebMock.allow_net_connect!

def persona_base_uri
  ENV.fetch('PERSONA_TEST_HOST', Talis::PERSONA_HOST)
end

def client_id
  ENV.fetch('PERSONA_OAUTH_CLIENT')
end

def client_secret
  ENV.fetch('PERSONA_OAUTH_SECRET')
end

def blueprint_base_uri
  ENV.fetch('BLUEPRINT_TEST_HOST', Talis::BLUEPRINT_HOST)
end

def echo_base_uri
  ENV.fetch('ECHO_TEST_HOST', Talis::ECHO_HOST)
end

def metatron_base_uri
  ENV.fetch('METATRON_TEST_HOST', Talis::METATRON_HOST)
end

def metatron_oauth_host
  ENV.fetch('METATRON_OAUTH_HOST', persona_base_uri)
end

def metatron_client_id
  ENV.fetch('METATRON_OAUTH_CLIENT', client_id)
end

def metatron_client_secret
  ENV.fetch('METATRON_OAUTH_SECRET', client_secret)
end

def babel_base_uri
  ENV.fetch('BABEL_TEST_HOST', Talis::BABEL_HOST)
end

RSpec.configure do |config|
  config.after(:each) do
    WebMock.after_request do |request|
      expected_user_agent = "talis-ruby-client/#{Talis::VERSION} "\
        "ruby/#{RUBY_VERSION}"
      expect(request.headers['User-Agent']).to eq expected_user_agent
      expect(request.headers['X-Request-Id']).to match(/[a-f0-9]{13}/)
    end
  end
end

def unique_id
  SecureRandom.hex(13) + '_' + Time.now.to_i.to_s
end
