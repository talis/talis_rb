require 'net/http'
require 'securerandom'
require_relative '../spec_helper'

describe Talis::Hierarchy::Asset do
  before do
    Talis::Authentication::Token.base_uri(persona_base_uri)
    Talis::Hierarchy::Asset.client_id = client_id
    Talis::Hierarchy::Asset.client_secret = client_secret
    Talis::Hierarchy::Asset.base_uri(blueprint_base_uri)

    setup_node_data
    setup_asset_data
  end

  context 'retrieving assets' do
    it 'returns a single asset' do
      asset = Talis::Hierarchy::Asset.get(namespace: 'rubytest',
                                          type: 'textbook',
                                          id: '0123456789'
                                         )

      expect(asset.id).to eq '0123456789'
      expect(asset.type).to eq 'textbook'
    end

    it 'returns nil when the asset is not found' do
      asset = Talis::Hierarchy::Asset.get(namespace: 'rubytest',
                                          type: 'textbook',
                                          id: 'notfound'
                                         )

      expect(asset).to be_nil
    end

    it 'raises an error when the server responds with a client error' do
      stub_request(:get, %r{1/rubytest/assets/textbook/0123456789}).to_return(
        status: [400]
      )

      opts = {
        namespace: 'rubytest',
        type: 'textbook',
        id: '0123456789'
      }
      expected_error = Talis::Errors::ClientError

      expect { Talis::Hierarchy::Asset.get(opts) }.to raise_error expected_error
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:get, %r{1/rubytest/assets/textbook/0123456789}).to_return(
        status: [500]
      )

      opts = {
        namespace: 'rubytest',
        type: 'textbook',
        id: '0123456789'
      }
      expected_error = Talis::Errors::ServerError

      expect { Talis::Hierarchy::Asset.get(opts) }.to raise_error expected_error
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Asset.base_uri('http://foo')

      opts = {
        namespace: 'rubytest',
        type: 'textbook',
        id: '0123456789'
      }
      expected_error = Talis::Errors::ServerCommunicationError

      expect { Talis::Hierarchy::Asset.get(opts) }.to raise_error expected_error
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Hierarchy::Asset.client_id = 'ruby-client-test'
      Talis::Hierarchy::Asset.client_secret = 'ruby-client-test'

      opts = {
        namespace: 'rubytest',
        type: 'textbook',
        id: '0123456789'
      }
      error = Talis::Errors::ClientError
      msg = 'The client credentials are invalid'

      expect { Talis::Hierarchy::Asset.get(opts) }.to raise_error error, msg
    end
  end

  context 'searching assets' do
    it 'returns all assets when no options are given' do
      assets = Talis::Hierarchy::Asset.find(namespace: 'rubytest',
                                            type: 'module',
                                            id: 'xyz'
                                           )
      asset = assets.last

      expect(assets.size).to eq 5
      expect(asset.id).to eq '0123456789'
      expect(asset.type).to eq 'textbook'
    end

    it 'returns an empty array when no assets are found' do
      assets = Talis::Hierarchy::Asset.find(namespace: 'rubytest',
                                            type: 'module',
                                            id: 'notfound'
                                           )

      expect(assets).to eq []
    end

    it 'raises an error when the server responds with a client error' do
      stub_request(:get, %r{1/rubytest/nodes/module/xyz/assets}).to_return(
        status: [400]
      )

      opts = {
        namespace: 'rubytest',
        type: 'module',
        id: 'xyz'
      }
      error = Talis::Errors::ClientError

      expect { Talis::Hierarchy::Asset.find(opts) }.to raise_error error
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:get, %r{1/rubytest/nodes/module/xyz/assets}).to_return(
        status: [500]
      )

      opts = {
        namespace: 'rubytest',
        type: 'module',
        id: 'xyz'
      }
      error = Talis::Errors::ServerError

      expect { Talis::Hierarchy::Asset.find(opts) }.to raise_error error
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Asset.base_uri('http://foo')

      opts = {
        namespace: 'rubytest',
        type: 'module',
        id: 'xyz'
      }
      error = Talis::Errors::ServerCommunicationError

      expect { Talis::Hierarchy::Asset.find(opts) }.to raise_error error
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Hierarchy::Asset.client_id = 'ruby-client-test'
      Talis::Hierarchy::Asset.client_secret = 'ruby-client-test'

      opts = {
        namespace: 'rubytest',
        type: 'module',
        id: 'xyz'
      }
      error = Talis::Errors::ClientError
      msg = 'The client credentials are invalid'

      expect { Talis::Hierarchy::Asset.find(opts) }.to raise_error error, msg
    end

    it 'can filter assets by the given property' do
      opts = {
        filter_asset_type: 'digitisation'
      }
      assets = Talis::Hierarchy::Asset.find(namespace: 'rubytest',
                                            type: 'module',
                                            id: 'xyz',
                                            opts: opts
                                           )

      expect(assets.size).to eq 3
      assets.each do |asset|
        expect(asset.type).to eq 'digitisation'
      end
    end

    it 'can limit the number of assets returned' do
      opts = {
        limit: 1
      }
      assets = Talis::Hierarchy::Asset.find(namespace: 'rubytest',
                                            type: 'module',
                                            id: 'xyz',
                                            opts: opts
                                           )

      expect(assets.size).to eq 1
    end

    it 'can offset the number of assets returned' do
      opts = {
        offset: 1
      }
      assets = Talis::Hierarchy::Asset.find(namespace: 'rubytest',
                                            type: 'module',
                                            id: 'xyz',
                                            opts: opts
                                           )
      asset = assets.first

      expect(asset.id).to eq '123'
      expect(asset.type).to eq 'digitisation'
    end

    it 'can apply multiple search options' do
      opts = {
        filter_asset_type: 'digitisation',
        offset: 1
      }
      assets = Talis::Hierarchy::Asset.find(namespace: 'rubytest',
                                            type: 'module',
                                            id: 'xyz',
                                            opts: opts
                                           )
      asset = assets.first

      expect(asset.id).to eq '456'
      expect(asset.type).to eq 'digitisation'
    end
  end

  private

  def assets
    {
      'aaa-bbb-ccc' => 'list',
      '123' => 'digitisation',
      '456' => 'digitisation',
      '789' => 'digitisation',
      '0123456789' => 'textbook'
    }
  end

  def setup_asset_data
    assets_api_client = Talis::Hierarchy::Asset.api_client
    assets.each do |id, type|
      begin
        assets_api_client.remove_asset_from_node('rubytest', 'module', 'xyz',
                                                 type, id)
      rescue BlueprintClient::ApiError => error
        # Asset probably didn't exist, this is OK
        puts "could not remove asset #{type}/#{id} from node: #{error.inspect}"
      end
      assets_api_client.add_asset_to_node('rubytest', 'module', 'xyz', type, id)
    end
  end

  def setup_node_data
    fixtures_dir = File.expand_path('../../fixtures', __FILE__)
    remove_hierarchy = File.read("#{fixtures_dir}/remove_asset_hierarchy.csv")
    add_hierarchy = File.read("#{fixtures_dir}/add_asset_hierarchy.csv")
    node_bulk_upload('rubytest', remove_hierarchy)
    node_bulk_upload('rubytest', add_hierarchy)
  end

  def token
    opts = { client_id: client_id, client_secret: client_secret }
    Talis::Authentication::Token.generate(opts).to_s
  end

  def headers
    {
      'Content-Type' => 'text/plain',
      'Authorization' => "Bearer #{token}",
      'X-Request-Id' => SecureRandom.hex(13),
      'User-Agent' => "talis-ruby-client/#{Talis::VERSION} "\
      "ruby/#{RUBY_VERSION}"
    }
  end

  # TODO: replace with blueprint_rb implementation when it is ready
  def node_bulk_upload(namespace, csv)
    uri = URI.parse("#{blueprint_base_uri}/1/#{namespace}/nodes.csv")
    request = Net::HTTP.new(uri.host, uri.port)
    request.use_ssl = (uri.scheme == 'https')
    expect(request.post(uri.path, csv, headers).code).to eq '204'
  end
end
