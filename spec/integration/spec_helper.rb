$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'talis'
require 'webmock/rspec'

WebMock.allow_net_connect!
