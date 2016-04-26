$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'talis'
require 'webmock/rspec'

WebMock.allow_net_connect!

def persona_base_uri
  ENV['PERSONA_TEST_HOST']
end

def client_id
  ENV['PERSONA_OAUTH_CLIENT']
end

def client_secret
  ENV['PERSONA_OAUTH_SECRET']
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
