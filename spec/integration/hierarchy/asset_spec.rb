require 'net/http'
require 'securerandom'
require_relative '../spec_helper'

describe Talis::Hierarchy::Asset do
  let(:namespace) { 'rubytest' }
  before do
    Talis::Authentication::Token.base_uri(persona_base_uri)
    Talis::Authentication.client_id = client_id
    Talis::Authentication.client_secret = client_secret
    Talis::Hierarchy::Asset.base_uri(blueprint_base_uri)

    setup_node_data
    setup_asset_data
  end

  context 'retrieving assets' do
    it 'returns a single asset' do
      asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                           type: 'textbooks',
                                           id: '0123456789')

      expect(asset).to be_an_instance_of Talis::Hierarchy::Asset
      expect(asset.id).to eq '0123456789'
      expect(asset.type).to eq 'textbooks'
    end

    it 'returns nil when the asset is not found' do
      asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                           type: 'textbooks',
                                           id: 'notfound')

      expect(asset).to be_nil
    end

    it 'raises an error when the server responds with a bad request error' do
      stub_request(:get, %r{1/rubytest/assets/textbooks/0123456789}).to_return(
        status: [400]
      )

      opts = {
        namespace: namespace,
        type: 'textbooks',
        id: '0123456789'
      }
      expected_err = Talis::BadRequestError

      expect { Talis::Hierarchy::Asset.find(opts) }.to raise_error expected_err
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:get, %r{1/rubytest/assets/textbooks/0123456789}).to_return(
        status: [500]
      )

      opts = {
        namespace: namespace,
        type: 'textbooks',
        id: '0123456789'
      }
      expected_err = Talis::ServerError

      expect { Talis::Hierarchy::Asset.find(opts) }.to raise_error expected_err
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Asset.base_uri('http://foo')

      opts = {
        namespace: namespace,
        type: 'textbooks',
        id: '0123456789'
      }
      expected_err = Talis::ServerCommunicationError

      expect { Talis::Hierarchy::Asset.find(opts) }.to raise_error expected_err
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'

      opts = {
        namespace: namespace,
        type: 'textbooks',
        id: '0123456789'
      }
      error = Talis::BadRequestError
      msg = 'The client credentials are invalid'

      expect { Talis::Hierarchy::Asset.find(opts) }.to raise_error error, msg
    end
  end

  context 'fetching all assets' do
    it 'returns all assets given just a namespace' do
      assets = Talis::Hierarchy::Asset.all(namespace: namespace)
      asset = assets.last

      expect(assets.size).to eq 5
      expect(asset).to be_an_instance_of Talis::Hierarchy::Asset
      expect(asset.id).to eq '0123456789'
      expect(asset.type).to eq 'textbooks'
    end

    it 'returns an empty array when no assets are found' do
      assets = Talis::Hierarchy::Asset.all(namespace: 'notfound')

      expect(assets).to eq []
    end

    it 'raises an error when the server responds with a bad request error' do
      stub_request(:get, %r{1/rubytest/assets}).to_return(status: [400])

      opts = { namespace: namespace }
      error = Talis::BadRequestError

      expect { Talis::Hierarchy::Asset.all(opts) }.to raise_error error
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:get, %r{1/rubytest/assets}).to_return(status: [500])

      opts = { namespace: namespace }
      error = Talis::ServerError

      expect { Talis::Hierarchy::Asset.all(opts) }.to raise_error error
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Asset.base_uri('http://foo')

      opts = { namespace: namespace }
      error = Talis::ServerCommunicationError

      expect { Talis::Hierarchy::Asset.all(opts) }.to raise_error error
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'

      opts = { namespace: namespace }
      err = Talis::BadRequestError
      msg = 'The client credentials are invalid'

      expect { Talis::Hierarchy::Asset.all(opts) }.to raise_error err, msg
    end
  end

  context 'searching assets' do
    it 'returns all assets when no options are given' do
      assets = Talis::Hierarchy::Asset.where(namespace: namespace)
      asset = assets.last

      expect(assets.size).to eq 5
      expect(asset).to be_an_instance_of Talis::Hierarchy::Asset
      expect(asset.id).to eq '0123456789'
      expect(asset.type).to eq 'textbooks'
    end

    it 'returns an empty array when no assets are found' do
      assets = Talis::Hierarchy::Asset.where(namespace: 'notfound')

      expect(assets).to eq []
    end

    it 'raises an error when the server responds with a bad request error' do
      stub_request(:get, %r{1/rubytest/assets}).to_return(status: [400])

      opts = { namespace: namespace }
      error = Talis::BadRequestError

      expect { Talis::Hierarchy::Asset.where(opts) }.to raise_error error
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:get, %r{1/rubytest/assets}).to_return(status: [500])

      opts = { namespace: namespace }
      error = Talis::ServerError

      expect { Talis::Hierarchy::Asset.where(opts) }.to raise_error error
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Asset.base_uri('http://foo')

      opts = { namespace: namespace }
      error = Talis::ServerCommunicationError

      expect { Talis::Hierarchy::Asset.where(opts) }.to raise_error error
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'

      opts = { namespace: namespace }
      err = Talis::BadRequestError
      msg = 'The client credentials are invalid'

      expect { Talis::Hierarchy::Asset.where(opts) }.to raise_error err, msg
    end

    it 'can filter assets by type' do
      opts = {
        filter_asset_type: ['digitisations']
      }
      assets = Talis::Hierarchy::Asset.where(namespace: namespace, opts: opts)

      expect(assets.size).to eq 3
      assets.each do |asset|
        expect(asset.type).to eq 'digitisations'
      end
    end

    it 'can limit the number of assets returned' do
      assets = Talis::Hierarchy::Asset.where(namespace: namespace,
                                             opts: { limit: 1 })

      expect(assets.size).to eq 1
    end

    it 'can offset the number of assets returned' do
      assets = Talis::Hierarchy::Asset.where(namespace: namespace,
                                             opts: { offset: 1 })
      asset = assets.first

      expect(asset.id).to eq '123'
      expect(asset.type).to eq 'digitisations'
    end

    it 'can apply multiple search options' do
      opts = {
        filter_asset_type: ['digitisations'],
        offset: 1
      }
      assets = Talis::Hierarchy::Asset.where(namespace: namespace,
                                             opts: opts)
      asset = assets.first

      expect(asset.id).to eq '456'
      expect(asset.type).to eq 'digitisations'
    end

    it 'can filter by multiple nodes as an and query' do
      assets = Talis::Hierarchy::Asset.where(namespace: namespace,
                                             opts: {
                                               filter_node: {
                                                 all: ['modules/xyz',
                                                       'modules/abc']
                                               }
                                             })

      # This will be zero because there are no assets that belong to
      # modules/abc
      expect(assets.size).to eq 0
    end

    it 'can filter by multiple nodes as an in query' do
      assets = Talis::Hierarchy::Asset.where(namespace: namespace,
                                             opts: {
                                               filter_node: {
                                                 any: ['modules/xyz',
                                                       'modules/abc']
                                               }
                                             })

      # This returns a result set because all the assets at least belong to
      # modules/xyz
      expect(assets.size).to eq 5
    end

    it 'raises an error given an invalid filter value' do
      opts = {
        namespace: namespace,
        opts: {
          filter_node: false
        }
      }
      error = ArgumentError
      msg = 'filter value must be an array or hash'

      expect { Talis::Hierarchy::Asset.where(opts) }.to raise_error error, msg
    end
  end

  context 'searching assets by node' do
    it 'returns all assets belonging to a node when no options are given' do
      assets = Talis::Hierarchy::Asset.find_by_node(namespace: namespace,
                                                    type: 'modules',
                                                    id: 'xyz')
      asset = assets.first

      expect(assets.size).to eq 5
      expect(asset).to be_an_instance_of Talis::Hierarchy::Asset
      expect(asset.id).to eq '0123456789'
      expect(asset.type).to eq 'textbooks'
    end

    it 'returns an empty array when no assets are found' do
      assets = Talis::Hierarchy::Asset.find_by_node(namespace: namespace,
                                                    type: 'modules',
                                                    id: 'notfound')

      expect(assets).to eq []
    end

    it 'raises an error when the server responds with a bad request error' do
      stub_request(:get, %r{1/rubytest/nodes/modules/xyz/assets}).to_return(
        status: [400]
      )

      opts = {
        namespace: namespace,
        type: 'modules',
        id: 'xyz'
      }
      error = Talis::BadRequestError

      expect { Talis::Hierarchy::Asset.find_by_node(opts) }.to raise_error error
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:get, %r{1/rubytest/nodes/modules/xyz/assets}).to_return(
        status: [500]
      )

      opts = {
        namespace: namespace,
        type: 'modules',
        id: 'xyz'
      }
      error = Talis::ServerError

      expect { Talis::Hierarchy::Asset.find_by_node(opts) }.to raise_error error
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Asset.base_uri('http://foo')

      opts = {
        namespace: namespace,
        type: 'modules',
        id: 'xyz'
      }
      error = Talis::ServerCommunicationError

      expect { Talis::Hierarchy::Asset.find_by_node(opts) }.to raise_error error
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'

      opts = {
        namespace: namespace,
        type: 'modules',
        id: 'xyz'
      }
      err = Talis::BadRequestError
      msg = 'The client credentials are invalid'

      expect { Talis::Hierarchy::Asset.find_by_node(opts) }.to raise_error err,
                                                                           msg
    end

    it 'can filter assets by the given property' do
      opts = {
        filter_asset_type: ['digitisations']
      }
      assets = Talis::Hierarchy::Asset.find_by_node(namespace: namespace,
                                                    type: 'modules',
                                                    id: 'xyz',
                                                    opts: opts)

      expect(assets.size).to eq 3
      assets.each do |asset|
        expect(asset.type).to eq 'digitisations'
      end
    end

    it 'can limit the number of assets returned' do
      opts = {
        limit: 1
      }
      assets = Talis::Hierarchy::Asset.find_by_node(namespace: namespace,
                                                    type: 'modules',
                                                    id: 'xyz',
                                                    opts: opts)

      expect(assets.size).to eq 1
    end

    it 'can offset the number of assets returned' do
      opts = {
        offset: 1
      }
      assets = Talis::Hierarchy::Asset.find_by_node(namespace: namespace,
                                                    type: 'modules',
                                                    id: 'xyz',
                                                    opts: opts)
      asset = assets.first

      expect(asset.id).to eq '789'
      expect(asset.type).to eq 'digitisations'
    end

    it 'can apply multiple search options' do
      opts = {
        filter_asset_type: ['digitisations'],
        offset: 1
      }
      assets = Talis::Hierarchy::Asset.find_by_node(namespace: namespace,
                                                    type: 'modules',
                                                    id: 'xyz',
                                                    opts: opts)
      asset = assets.first

      expect(asset.id).to eq '456'
      expect(asset.type).to eq 'digitisations'
    end
  end

  context 'creating assets' do
    let(:asset) do
      node = OpenStruct.new(id: 'xyz', type: 'modules')
      options = {
        namespace: namespace,
        type: 'notes',
        id: '999',
        nodes: [node]
      }
      Talis::Hierarchy::Asset.new(options)
    end

    let(:asset_with_multiple_nodes) do
      node1 = OpenStruct.new(id: 'xyz', type: 'modules')
      node2 = OpenStruct.new(id: 'def', type: 'modules')
      options = {
        namespace: namespace,
        type: 'notes',
        id: '999',
        nodes: [node1, node2]
      }
      Talis::Hierarchy::Asset.new(options)
    end

    it 'saves a valid asset' do
      expected_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                    type: 'notes',
                                                    id: '999')
      expect(expected_asset).to be_nil

      asset.save

      created_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                   type: 'notes',
                                                   id: '999')

      expect(created_asset.id).to eq '999'
      expect(created_asset.type).to eq 'notes'

      assert_asset_associated_with_node(created_asset,
                                        namespace,
                                        'modules',
                                        'xyz')
    end

    it 'saves a valid asset with multiple nodes' do
      expected_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                    type: 'notes',
                                                    id: '999')
      expect(expected_asset).to be_nil

      asset_with_multiple_nodes.save

      created_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                   type: 'notes',
                                                   id: '999')

      expect(created_asset.id).to eq '999'
      expect(created_asset.type).to eq 'notes'

      assert_asset_associated_with_node(created_asset,
                                        namespace,
                                        'modules',
                                        'xyz')
      assert_asset_associated_with_node(created_asset,
                                        namespace,
                                        'modules',
                                        'def')
    end

    it 'raises an error when the server responds with a bad request error' do
      stub_request(:put, %r{1/rubytest/nodes/modules/xyz/assets/notes/999})
        .to_return(status: [400])

      expect { asset.save }.to raise_error Talis::BadRequestError
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:put, %r{1/rubytest/nodes/modules/xyz/assets/notes/999})
        .to_return(status: [500])

      expect { asset.save }.to raise_error Talis::ServerError
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Asset.base_uri('http://foo')
      expected_error = Talis::ServerCommunicationError

      expect { asset.save }.to raise_error expected_error
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'
      message = 'The client credentials are invalid'

      expect { asset.save }.to raise_error Talis::BadRequestError, message
    end
  end

  context 'updating assets' do
    let(:asset) do
      node = OpenStruct.new(id: 'xyz', type: 'modules')
      options = {
        namespace: namespace,
        type: 'notes',
        id: '999',
        nodes: [node]
      }
      Talis::Hierarchy::Asset.new(options)
    end

    it 'should update a valid asset' do
      asset.save
      existing_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                    type: 'notes',
                                                    id: '999')
      expect(existing_asset.attributes).to eq({})

      existing_asset.attributes = { test: 'attribute' }
      existing_asset.update

      updated_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                   type: 'notes',
                                                   id: '999')
      expect(updated_asset.attributes[:test]).to eq 'attribute'
    end

    it 'should update a valid asset without attributes' do
      id = unique_id
      node = OpenStruct.new(id: 'xyz', type: 'modules')
      new_asset = Talis::Hierarchy::Asset.new(namespace: namespace,
                                              nodes: [node],
                                              type: 'notes', id: id)
      new_asset.save
      existing_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                    type: 'notes',
                                                    id: id)
      expect(existing_asset.attributes).to eq({})
      expect(existing_asset.id).to eq(id)
      expect(existing_asset.type).to eq('notes')

      existing_asset.type = 'lists'
      expect(existing_asset.type).to eq('lists')
      expect(existing_asset.stored_type).to eq('notes')
      existing_asset.update

      updated_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                   type: 'lists',
                                                   id: id)
      expect(updated_asset).not_to be_nil

      old_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                               type: 'notes',
                                               id: id)
      expect(old_asset).to be_nil

      new_id = unique_id

      existing_asset.id = new_id

      existing_asset.update

      updated_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                   type: 'lists',
                                                   id: new_id)
      expect(updated_asset).not_to be_nil

      previous_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                    type: 'lists',
                                                    id: id)

      expect(previous_asset).to be_nil

      original_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                    type: 'notes',
                                                    id: id)

      expect(original_asset).to be_nil

      # o/~ Clean up, clean up, everybody do their share o/~
      updated_asset.delete
    end

    it 'should update a valid asset with a new node' do
      asset.save
      existing_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                    type: 'notes',
                                                    id: '999')
      node2 = OpenStruct.new(id: 'def', type: 'modules')
      existing_asset.nodes = [node2]
      existing_asset.save

      assert_asset_associated_with_node(existing_asset,
                                        namespace,
                                        'modules',
                                        'xyz')
      assert_asset_associated_with_node(existing_asset,
                                        namespace,
                                        'modules',
                                        'def')
    end

    it 'should update an asset but not error on existing nodes' do
      asset.save
      existing_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                    type: 'notes',
                                                    id: '999')
      existing_node = OpenStruct.new(id: 'xyz', type: 'modules')
      new_node = OpenStruct.new(id: 'def', type: 'modules')
      existing_asset.nodes = [existing_node, new_node]
      existing_asset.save

      assert_asset_associated_with_node(existing_asset,
                                        namespace,
                                        'modules',
                                        'xyz')
      assert_asset_associated_with_node(existing_asset,
                                        namespace,
                                        'modules',
                                        'def')
    end

    it 'raises an error when the server responds with a bad request error' do
      stub_request(:put, %r{1/rubytest/assets/notes/999}).to_return(
        status: [400]
      )

      expect { asset.update }.to raise_error Talis::BadRequestError
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:put, %r{1/rubytest/assets/notes/999}).to_return(
        status: [500]
      )

      expect { asset.update }.to raise_error Talis::ServerError
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Asset.base_uri('http://foo')
      expected_error = Talis::ServerCommunicationError

      expect { asset.update }.to raise_error expected_error
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'
      message = 'The client credentials are invalid'

      expect { asset.update }.to raise_error Talis::BadRequestError, message
    end
  end

  context 'deleting assets' do
    let(:asset) do
      node = OpenStruct.new(id: 'xyz', type: 'modules')
      options = {
        namespace: namespace,
        type: 'notes',
        id: '999',
        nodes: [node]
      }
      Talis::Hierarchy::Asset.new(options)
    end

    it 'should delete a valid asset' do
      asset.save
      existing_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                    type: 'notes',
                                                    id: '999')
      expect(existing_asset).not_to be_nil

      asset.delete
      deleted_asset = Talis::Hierarchy::Asset.find(namespace: namespace,
                                                   type: 'notes',
                                                   id: '999')

      expect(deleted_asset).to be_nil
    end

    it 'raises an error when the server responds with a bad request error' do
      stub_request(:delete, %r{1/rubytest/assets/notes/999}).to_return(
        status: [400]
      )

      expect { asset.delete }.to raise_error Talis::BadRequestError
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:delete, %r{1/rubytest/assets/notes/999}).to_return(
        status: [500]
      )

      expect { asset.delete }.to raise_error Talis::ServerError
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Asset.base_uri('http://foo')
      expected_error = Talis::ServerCommunicationError

      expect { asset.delete }.to raise_error expected_error
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'
      message = 'The client credentials are invalid'

      expect { asset.delete }.to raise_error Talis::BadRequestError, message
    end
  end

  private

  def assets
    {
      'aaa-bbb-ccc' => 'lists',
      '123' => 'digitisations',
      '456' => 'digitisations',
      '789' => 'digitisations',
      '0123456789' => 'textbooks',
      '999' => 'notes'
    }
  end

  def setup_asset_data
    assets_api_client = Talis::Hierarchy::Asset.api_client
    assets.each do |id, type|
      begin
        assets_api_client.delete_asset(namespace, id, type)
      rescue BlueprintClient::ApiError => error
        # Asset probably didn't exist, this is OK
        puts "could not remove asset #{type}/#{id}: #{error.inspect}"
      end
      assets_api_client.add_asset_to_node(namespace, 'modules', 'xyz', type, id)
      assets_api_client.delete_asset(namespace, '999', 'notes')
    end
  end

  def setup_node_data
    fixtures_dir = File.expand_path('../../fixtures', __FILE__)
    remove_hierarchy = File.read("#{fixtures_dir}/remove_asset_hierarchy.csv")
    add_hierarchy = File.read("#{fixtures_dir}/add_asset_hierarchy.csv")
    node_bulk_upload(namespace, remove_hierarchy)
    node_bulk_upload(namespace, add_hierarchy)
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

  def assert_asset_associated_with_node(asset, namespace, type, id)
    found_assets = Talis::Hierarchy::Asset.find_by_node(namespace: namespace,
                                                        type: type,
                                                        id: id)
    match = found_assets.any? { |a| a.id == asset.id && a.type == asset.type }
    expect(match).to be true
  end
end
