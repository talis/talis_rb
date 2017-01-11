require_relative '../spec_helper'
require 'blueprint_ruby_client'

describe Talis::Hierarchy::Node do
  let(:namespace) { 'rubytest' }
  let(:mutated_namespace) { 'rubyappendtest' }
  before do
    Talis::Authentication::Token.base_uri(persona_base_uri)
    Talis::Authentication.client_id = client_id
    Talis::Authentication.client_secret = client_secret
    Talis::Hierarchy::Node.base_uri(blueprint_base_uri)
    Talis::Hierarchy::Asset.base_uri(blueprint_base_uri)

    setup_node_data
  end

  context 'retrieving nodes' do
    it 'returns a single node' do
      node = Talis::Hierarchy::Node.get(namespace: namespace,
                                        type: 'colleges',
                                        id: 'abc')

      expect(node.id).to eq 'abc'
      expect(node.type).to eq 'colleges'
      expect(node.attributes.title).to eq 'College of ABC'
      expect(node.attributes.description).to eq 'Where one learns how to '\
        'properly AB their Cs'
      expect(node.attributes.domain_ids).to eq ['jacs:1234']
    end

    it 'returns nil when the node is not found' do
      node = Talis::Hierarchy::Node.get(namespace: 'notfound',
                                        type: 'colleges',
                                        id: 'abc')

      expect(node).to be_nil
    end

    it 'raises an error when the server responds with a bad request' do
      stub_request(:get, %r{1/rubytest/nodes/colleges/abc}).to_return(
        status: [400]
      )

      opts = {
        namespace: namespace,
        type: 'colleges',
        id: 'abc'
      }
      expected_error = Talis::BadRequestError

      expect { Talis::Hierarchy::Node.get(opts) }.to raise_error expected_error
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:get, %r{1/rubytest/nodes/colleges/abc}).to_return(
        status: [500]
      )

      opts = {
        namespace: namespace,
        type: 'colleges',
        id: 'abc'
      }
      expected_error = Talis::ServerError

      expect { Talis::Hierarchy::Node.get(opts) }.to raise_error expected_error
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Node.base_uri('http://foo')

      opts = {
        namespace: namespace,
        type: 'colleges',
        id: 'abc'
      }
      expected_error = Talis::ServerCommunicationError

      expect { Talis::Hierarchy::Node.get(opts) }.to raise_error expected_error
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'

      opts = {
        namespace: namespace,
        type: 'colleges',
        id: 'abc'
      }
      expected_error = Talis::BadRequestError
      msg = 'The client credentials are invalid'

      expect { Talis::Hierarchy::Node.get(opts) }.to raise_error expected_error,
                                                                 msg
    end
  end

  context 'searching nodes' do
    it 'returns all nodes when no options are given' do
      nodes = Talis::Hierarchy::Node.find(namespace: namespace).data
      node = nodes.first

      expect(nodes.size).to eq 6
      expect(node.id).to eq 'abc'
      expect(node.type).to eq 'colleges'
      expect(node.attributes.title).to eq 'College of ABC'
      expect(node.attributes.description).to eq 'Where one learns how to '\
        'properly AB their Cs'
      expect(node.attributes.domain_ids).to eq ['jacs:1234']
    end

    it 'returns an empty array when no nodes are found' do
      nodes = Talis::Hierarchy::Node.find(namespace: 'notfound').data

      expect(nodes).to eq []
    end

    it 'raises an error when the server responds with a bad request' do
      stub_request(:get, %r{1/rubytest/nodes}).to_return(status: [400])

      opts = {
        namespace: namespace
      }
      expected_error = Talis::BadRequestError

      expect { Talis::Hierarchy::Node.find(opts) }.to raise_error expected_error
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:get, %r{1/rubytest/nodes}).to_return(status: [500])

      opts = {
        namespace: namespace
      }
      expected_error = Talis::ServerError

      expect { Talis::Hierarchy::Node.find(opts) }.to raise_error expected_error
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Node.base_uri('http://foo')

      opts = {
        namespace: namespace
      }
      expected_error = Talis::ServerCommunicationError

      expect { Talis::Hierarchy::Node.find(opts) }.to raise_error expected_error
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'

      opts = {
        namespace: namespace
      }
      error = Talis::BadRequestError
      msg = 'The client credentials are invalid'

      expect { Talis::Hierarchy::Node.find(opts) }.to raise_error error, msg
    end

    it 'can filter nodes by the given property' do
      opts = {
        filter_node_type: ['courses']
      }
      nodes = Talis::Hierarchy::Node.find(namespace: namespace, opts: opts).data

      expect(nodes.size).to eq 2
      nodes.each do |node|
        expect(node.type).to eq 'courses'
      end
    end

    it 'can limit the number of nodes returned' do
      opts = {
        limit: 1
      }
      nodes = Talis::Hierarchy::Node.find(namespace: namespace, opts: opts).data

      expect(nodes.size).to eq 1
    end

    it 'can offset the number of nodes returned' do
      opts = {
        offset: 1
      }
      nodes = Talis::Hierarchy::Node.find(namespace: namespace, opts: opts).data
      node = nodes.first

      expect(node.id).to eq 'lmnop'
      expect(node.type).to eq 'departments'
      expect(node.attributes.title).to eq 'Department of LMNOP'
      expect(node.attributes.description).to eq 'Elle Emino P'
      expect(node.attributes.domain_ids).to eq ['jacs:2345']
    end

    it 'can apply multiple search options' do
      opts = {
        filter_node_type: ['courses'],
        offset: 1
      }
      nodes = Talis::Hierarchy::Node.find(namespace: namespace, opts: opts).data
      node = nodes.first

      expect(node.id).to eq 'qr'
      expect(node.type).to eq 'courses'
      expect(node.attributes.title).to eq 'Intermediate QR'
      expect(node.attributes.description).to eq 'Applied QR for QRists'
      expect(node.attributes.domain_ids).to eq ['jacs:4567']
    end
  end

  context 'hydrating nodes' do
    pending 'TODO: Waiting on blueprint implementation'
  end

  context 'retrieving children from a node' do
    it 'returns all children' do
      children = Talis::Hierarchy::Node.children(namespace: namespace,
                                                 type: 'colleges',
                                                 id: 'abc')
      node = children.first

      expect(children.size).to eq 1
      expect(node.id).to eq 'lmnop'
      expect(node.type).to eq 'departments'
      expect(node.attributes.title).to eq 'Department of LMNOP'
      expect(node.attributes.description).to eq 'Elle Emino P'
      expect(node.attributes.domain_ids).to eq ['jacs:2345']
    end

    it 'returns an empty array when no children are found' do
      children = Talis::Hierarchy::Node.children(namespace: namespace,
                                                 type: 'modules',
                                                 id: 'xyz')

      expect(children).to eq []
    end

    it 'raises an error when the server responds with a bad request' do
      stub_request(:get, %r{1/rubytest/nodes/colleges/abc/children}).to_return(
        status: [400]
      )

      opts = {
        namespace: namespace,
        type: 'colleges',
        id: 'abc'
      }
      error = Talis::BadRequestError

      expect { Talis::Hierarchy::Node.children(opts) }.to raise_error error
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:get, %r{1/rubytest/nodes/colleges/abc/children}).to_return(
        status: [500]
      )

      opts = {
        namespace: namespace,
        type: 'colleges',
        id: 'abc'
      }
      error = Talis::ServerError

      expect { Talis::Hierarchy::Node.children(opts) }.to raise_error error
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Node.base_uri('http://foo')

      opts = {
        namespace: namespace,
        type: 'colleges',
        id: 'abc'
      }
      error = Talis::ServerCommunicationError

      expect { Talis::Hierarchy::Node.children(opts) }.to raise_error error
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'

      opts = {
        namespace: namespace,
        type: 'colleges',
        id: 'abc'
      }
      error = Talis::BadRequestError
      msg = 'The client credentials are invalid'

      expect { Talis::Hierarchy::Node.children(opts) }.to raise_error error,
                                                                      msg
    end

    it 'can limit and offset the number of children returned' do
      opts = {
        limit: 1,
        offset: 1
      }

      children = Talis::Hierarchy::Node.children(namespace: namespace,
                                                 type: 'departments',
                                                 id: 'lmnop',
                                                 opts: opts)
      node = children.first

      expect(children.size).to eq 1
      expect(node.id).to eq 'qr'
      expect(node.type).to eq 'courses'
      expect(node.attributes.title).to eq 'Intermediate QR'
      expect(node.attributes.description).to eq 'Applied QR for QRists'
      expect(node.attributes.domain_ids).to eq ['jacs:4567']
    end
  end

  context 'retrieving parents from a node' do
    it 'returns all parents' do
      parents = Talis::Hierarchy::Node.parents(namespace: namespace,
                                               type: 'departments',
                                               id: 'lmnop')
      node = parents.first

      expect(parents.size).to eq 1
      expect(node.id).to eq 'abc'
      expect(node.type).to eq 'colleges'
      expect(node.attributes.title).to eq 'College of ABC'
      expect(node.attributes.description).to eq 'Where one learns how to '\
        'properly AB their Cs'
      expect(node.attributes.domain_ids).to eq ['jacs:1234']
    end

    it 'returns an empty array when no parents are found' do
      parents = Talis::Hierarchy::Node.parents(namespace: namespace,
                                               type: 'colleges',
                                               id: 'abc')

      expect(parents).to eq []
    end

    it 'raises an error when the server responds with a bad request' do
      stub_request(:get, %r{1/rubytest/nodes/departments/lmnop/parents})
        .to_return(status: [400])

      opts = {
        namespace: namespace,
        type: 'departments',
        id: 'lmnop'
      }
      error = Talis::BadRequestError

      expect { Talis::Hierarchy::Node.parents(opts) }.to raise_error error
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:get, %r{1/rubytest/nodes/departments/lmnop/parents})
        .to_return(status: [500])

      opts = {
        namespace: namespace,
        type: 'departments',
        id: 'lmnop'
      }
      error = Talis::ServerError

      expect { Talis::Hierarchy::Node.parents(opts) }.to raise_error error
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Node.base_uri('http://foo')

      opts = {
        namespace: namespace,
        type: 'departments',
        id: 'lmnop'
      }
      error = Talis::ServerCommunicationError

      expect { Talis::Hierarchy::Node.parents(opts) }.to raise_error error
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'

      opts = {
        namespace: namespace,
        type: 'departments',
        id: 'lmnop'
      }
      error = Talis::BadRequestError
      msg = 'The client credentials are invalid'

      expect { Talis::Hierarchy::Node.parents(opts) }.to raise_error error,
                                                                     msg
    end

    it 'can limit and offset the number of parents returned' do
      opts = {
        limit: 1,
        offset: 0
      }

      parents = Talis::Hierarchy::Node.parents(namespace: namespace,
                                               type: 'departments',
                                               id: 'lmnop',
                                               opts: opts)
      node = parents.first

      expect(parents.size).to eq 1
      expect(node.id).to eq 'abc'
      expect(node.type).to eq 'colleges'
      expect(node.attributes.title).to eq 'College of ABC'
      expect(node.attributes.description).to eq 'Where one learns how to '\
        'properly AB their Cs'
      expect(node.attributes.domain_ids).to eq ['jacs:1234']
    end
  end

  context 'retrieving ancestors from a node' do
    it 'returns all ancestors' do
      ancestors = Talis::Hierarchy::Node.ancestors(namespace: namespace,
                                                   type: 'courses',
                                                   id: 'stuv')
      node = ancestors.first

      expect(ancestors.size).to eq 2
      expect(node.id).to eq 'abc'
      expect(node.type).to eq 'colleges'
      expect(node.attributes.title).to eq 'College of ABC'
      expect(node.attributes.description).to eq 'Where one learns how to '\
        'properly AB their Cs'
      expect(node.attributes.domain_ids).to eq ['jacs:1234']
    end

    it 'returns an empty array when no ancestors are found' do
      ancestors = Talis::Hierarchy::Node.ancestors(namespace: namespace,
                                                   type: 'colleges',
                                                   id: 'abc')

      expect(ancestors).to eq []
    end

    it 'raises an error when the server responds with a bad request' do
      stub_request(:get, %r{1/rubytest/nodes/courses/stuv/ancestors}).to_return(
        status: [400]
      )

      opts = {
        namespace: namespace,
        type: 'courses',
        id: 'stuv'
      }
      error = Talis::BadRequestError

      expect { Talis::Hierarchy::Node.ancestors(opts) }.to raise_error error
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:get, %r{1/rubytest/nodes/courses/stuv/ancestors}).to_return(
        status: [500]
      )

      opts = {
        namespace: namespace,
        type: 'courses',
        id: 'stuv'
      }
      error = Talis::ServerError

      expect { Talis::Hierarchy::Node.ancestors(opts) }.to raise_error error
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Node.base_uri('http://foo')

      opts = {
        namespace: namespace,
        type: 'course',
        id: 'stuv'
      }
      error = Talis::ServerCommunicationError

      expect { Talis::Hierarchy::Node.ancestors(opts) }.to raise_error error
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'

      opts = {
        namespace: namespace,
        type: 'courses',
        id: 'stuv'
      }
      error = Talis::BadRequestError
      msg = 'The client credentials are invalid'

      expect { Talis::Hierarchy::Node.ancestors(opts) }.to raise_error error,
                                                                       msg
    end

    it 'can limit and offset the number of ancestors returned' do
      opts = {
        limit: 1,
        offset: 1
      }

      ancestors = Talis::Hierarchy::Node.ancestors(namespace: namespace,
                                                   type: 'courses',
                                                   id: 'stuv',
                                                   opts: opts)
      node = ancestors.first

      expect(ancestors.size).to eq 1
      expect(node.id).to eq 'lmnop'
      expect(node.type).to eq 'departments'
      expect(node.attributes.title).to eq 'Department of LMNOP'
      expect(node.attributes.description).to eq 'Elle Emino P'
      expect(node.attributes.domain_ids).to eq ['jacs:2345']
    end
  end

  context 'retrieving descendants from a node' do
    it 'returns all descendants' do
      descendants = Talis::Hierarchy::Node.descendants(namespace: namespace,
                                                       type: 'departments',
                                                       id: 'lmnop')
      node = descendants.first

      expect(descendants.size).to eq 4
      expect(node.id).to eq 'stuv'
      expect(node.type).to eq 'courses'
      expect(node.attributes.title).to eq 'Introduction to STUV'
      expect(node.attributes.description).to eq 'Elementary STUV'
      expect(node.attributes.domain_ids).to eq ['jacs:3456']
    end

    it 'returns an empty array when no descendants are found' do
      descendants = Talis::Hierarchy::Node.descendants(namespace: namespace,
                                                       type: 'modules',
                                                       id: 'xyz')

      expect(descendants).to eq []
    end

    it 'raises an error when the server responds with a bad request' do
      stub_request(:get, %r{1/rubytest/nodes/colleges/abc/descendants})
        .to_return(status: [400])

      opts = {
        namespace: namespace,
        type: 'colleges',
        id: 'abc'
      }
      error = Talis::ClientError

      expect { Talis::Hierarchy::Node.descendants(opts) }.to raise_error error
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:get, %r{1/rubytest/nodes/colleges/abc/descendants})
        .to_return(status: [500])

      opts = {
        namespace: namespace,
        type: 'colleges',
        id: 'abc'
      }
      error = Talis::ServerError

      expect { Talis::Hierarchy::Node.descendants(opts) }.to raise_error error
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Node.base_uri('http://foo')

      opts = {
        namespace: namespace,
        type: 'colleges',
        id: 'abc'
      }
      error = Talis::ServerCommunicationError

      expect { Talis::Hierarchy::Node.descendants(opts) }.to raise_error error
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'

      opts = {
        namespace: namespace,
        type: 'colleges',
        id: 'abc'
      }
      error = Talis::ClientError
      msg = 'The client credentials are invalid'

      expect { Talis::Hierarchy::Node.descendants(opts) }.to raise_error error,
                                                                         msg
    end

    it 'can limit and offset the number of descendants returned' do
      opts = {
        limit: 1,
        offset: 1
      }

      descendants = Talis::Hierarchy::Node.descendants(namespace: namespace,
                                                       type: 'departments',
                                                       id: 'lmnop',
                                                       opts: opts)
      node = descendants.first

      expect(descendants.size).to eq 1
      expect(node.id).to eq 'qr'
      expect(node.type).to eq 'courses'
      expect(node.attributes.title).to eq 'Intermediate QR'
      expect(node.attributes.description).to eq 'Applied QR for QRists'
      expect(node.attributes.domain_ids).to eq ['jacs:4567']
    end
  end

  context 'adding nodes' do
    it 'create a single node' do
      id = 'add_single_node_' + unique_id
      attributes = {
        title: 'Add a Single Node Test'
      }

      node = Talis::Hierarchy::Node.create(namespace: mutated_namespace,
                                           type: 'tests',
                                           id: id,
                                           attributes: attributes)

      expect(node.id).to eq id
      expect(node.type).to eq 'tests'
      expect(node.attributes.title).to eq 'Add a Single Node Test'

      found_node = Talis::Hierarchy::Node.get(namespace: mutated_namespace,
                                              type: 'tests', id: id)

      expect(found_node.id).to eq node.id
      expect(found_node.type).to eq node.type
      expect(found_node.attributes.title).to eq node.attributes.title
    end

    it 'raises an error when the server responds with a bad request' do
      stub_request(:post, %r{1/rubyappendtest/nodes}).to_return(
        status: [400]
      )

      id = 'add_single_node_' + unique_id
      attributes = {
        'title' => 'Add a Single Node Test'
      }

      expected = expect do
        Talis::Hierarchy::Node.create(namespace: mutated_namespace,
                                      type: 'tests',
                                      id: id,
                                      attributes: attributes)
      end

      expected.to raise_error Talis::ClientError
    end

    it 'raises an error when the server responds with a conflict error' do
      stub_request(:post, %r{1/rubyappendtest/nodes}).to_return(
        status: [409]
      )

      id = 'add_single_node_' + unique_id
      attributes = {
        'title' => 'Add a Single Node Test'
      }

      expected = expect do
        Talis::Hierarchy::Node.create(namespace: mutated_namespace,
                                      type: 'tests',
                                      id: id,
                                      attributes: attributes)
      end

      expected.to raise_error Talis::ConflictError
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:post, %r{1/rubyappendtest/nodes}).to_return(
        status: [500]
      )

      id = 'add_single_node_' + unique_id
      attributes = {
        'title' => 'Add a Single Node Test'
      }

      expected = expect do
        Talis::Hierarchy::Node.create(namespace: mutated_namespace,
                                      type: 'tests',
                                      id: id,
                                      attributes: attributes)
      end

      expected.to raise_error Talis::ServerError
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Hierarchy::Node.base_uri('http://foo')

      id = 'add_single_node_' + unique_id
      attributes = {
        'title' => 'Add a Single Node Test'
      }

      expected = expect do
        Talis::Hierarchy::Node.create(namespace: mutated_namespace,
                                      type: 'tests',
                                      id: id,
                                      attributes: attributes)
      end

      expected.to raise_error Talis::ServerCommunicationError
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'

      Talis::Hierarchy::Node.base_uri('http://foo')

      id = 'add_single_node_' + unique_id
      attributes = {
        'title' => 'Add a Single Node Test'
      }

      expected = expect do
        Talis::Hierarchy::Node.create(namespace: mutated_namespace,
                                      type: 'tests',
                                      id: id,
                                      attributes: attributes)
      end

      expected.to raise_error Talis::ClientError
    end
  end

  context 'searching asset.node relationships' do
    let(:asset_node_namespace) { "rubytest#{Time.now.to_i}" }
    before do
      setup_asset_node_data(asset_node_namespace)
    end
    it 'should find nodes with assets related to another node' do
      opts = {
        filter_asset_node: ['redemption_periods/123'],
        filter_node_type: ['modules']
      }
      nodes = Talis::Hierarchy::Node.find(namespace: asset_node_namespace,
                                          opts: opts).data

      expect(nodes.size).to eq 3
      nodes.each do |node|
        expect(node.type).to eq 'modules'
      end

      expect(nodes.map(&:id)).to contain_exactly(
        'abc', 'def', 'ghi'
      )
    end

    it 'should find nodes with typed assets related to another node' do
      opts = {
        filter_asset_node: ['redemption_periods/456'],
        filter_asset_type: ['coretext_preferences_received'],
        filter_node_type: ['modules']
      }
      nodes = Talis::Hierarchy::Node.find(namespace: asset_node_namespace,
                                          opts: opts).data

      expect(nodes.size).to eq 1
      nodes.each do |node|
        expect(node.type).to eq 'modules'
        expect(node.id).to eq 'jkl'
      end
    end

    it 'should find descendants with assets related to another node' do
      opts = {
        filter_asset_node: ['redemption_periods/456'],
        filter_ancestor: ['schools/zyx'],
        filter_node_type: ['modules']
      }
      nodes = Talis::Hierarchy::Node.find(namespace: asset_node_namespace,
                                          opts: opts).data

      expect(nodes.size).to eq 2
      nodes.each do |node|
        expect(node.type).to eq 'modules'
      end

      expect(nodes.map(&:id)).to contain_exactly(
        'abc', 'def'
      )
    end

    it 'should find descendants with typed assets related to another node' do
      opts = {
        filter_asset_node: ['redemption_periods/456'],
        filter_asset_type: ['coretext_preferences_in_progress'],
        filter_ancestor: ['schools/wvu'],
        filter_node_type: ['modules']
      }
      nodes = Talis::Hierarchy::Node.find(namespace: asset_node_namespace,
                                          opts: opts).data

      expect(nodes.size).to eq 1
      nodes.each do |node|
        expect(node.type).to eq 'modules'
        expect(node.id).to eq 'ghi'
      end
    end

    after do
      teardown_asset_node_data(asset_node_namespace)
    end
  end

  private

  def setup_node_data
    fixtures_dir = File.expand_path('../../fixtures', __FILE__)
    remove_hierarchy = File.read("#{fixtures_dir}/remove_node_hierarchy.csv")
    add_hierarchy = File.read("#{fixtures_dir}/add_node_hierarchy.csv")
    node_bulk_upload('rubytest', remove_hierarchy)
    node_bulk_upload('rubytest', add_hierarchy)
    node_bulk_upload('rubyappendtest', remove_hierarchy)
    node_bulk_upload('rubyappendtest', add_hierarchy)
  end

  def setup_asset_node_data(namespace)
    fixtures_dir = File.expand_path('../../fixtures', __FILE__)
    hiera_file = 'node_asset_relns_hierarchy'
    remove_hierarchy = File.read("#{fixtures_dir}/remove_#{hiera_file}.csv")
    add_hierarchy = File.read("#{fixtures_dir}/add_#{hiera_file}.csv")
    assets = JSON.load File.read(
      "#{fixtures_dir}/node_asset_relns_assets.json"
    )
    node_bulk_upload(namespace, remove_hierarchy)
    node_bulk_upload(namespace, add_hierarchy)
    add_assets(assets, namespace)
  end

  def teardown_asset_node_data(namespace)
    fixtures_dir = File.expand_path('../../fixtures', __FILE__)
    remove_hierarchy = File.read(
      "#{fixtures_dir}/remove_node_asset_relns_hierarchy.csv"
    )
    assets = JSON.load File.read(
      "#{fixtures_dir}/node_asset_relns_assets.json"
    )
    node_bulk_upload(namespace, remove_hierarchy)
    remove_assets(assets, namespace)
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

  def add_assets(asset_data, namespace)
    asset_data.each do |asset_id, data|
      nodes = data['nodes'].map do |node_data|
        OpenStruct.new(id: node_data['id'], type: node_data['type'])
      end
      asset = Talis::Hierarchy::Asset.new(id: asset_id, type: data['type'],
                                          nodes: nodes, namespace: namespace)
      asset.save
    end
  end

  def remove_assets(asset_data, namespace)
    asset_data.each do |asset_id, data|
      asset = Talis::Hierarchy::Asset.new(id: asset_id, type: data['type'],
                                          namespace: namespace)
      asset.delete
    end
  end
end
