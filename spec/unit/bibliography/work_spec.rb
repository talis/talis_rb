require_relative '../spec_helper'

describe Talis::Bibliography::Work do
  let(:request_id) { 'a1b2c3d4e5f60' }
  context 'escaping works search queries' do
    it 'should not escape reserved characters in query by default' do
      query = '"/the + quick - brown: = fo\x && jumps || {over} > the <' \
        ' (lazy) ~ dog?!'
      params = { q: query, offset: 0, limit: 20, include: '' }
      search_url = stub_metatron_request(request_id, params)
      expect(Talis::Bibliography::Work).to receive(:token).and_return('foobar')

      Talis::Bibliography::Work.find(request_id: request_id, query: query)
      expect(a_request(:get, search_url).with(query: params)).to have_been_made
    end

    it 'should escape reserved characters if requested' do
      query = '"/the + quick - brown: = fo\x && jumps || {over} > the <' \
        ' (lazy) ~ dog?!'
      expected_query = '\"\/the \+ quick \- brown\: \= fo\\\x \&& jumps \||' \
        ' \{over\} \> the \< \(lazy\) \~ dog\?\!'

      params = { q: expected_query, offset: 0, limit: 20, include: '' }
      search_url = stub_metatron_request(request_id, params)
      expect(Talis::Bibliography::Work).to receive(:token).and_return('foobar')

      Talis::Bibliography::Work.find(request_id: request_id, query: query,
                                     include: [], opts: { escape_query: true })
      expect(a_request(:get, search_url).with(query: params)).to have_been_made
    end
  end

  context 'passing search options' do
    it 'should set defaults for includes, offset, and limit' do
      params = { q: 'foo bar baz', offset: 0, limit: 20, include: '' }
      search_url = stub_metatron_request(request_id, params)
      expect(Talis::Bibliography::Work).to receive(:token).and_return('foobar')
      Talis::Bibliography::Work.find(request_id: request_id, query: params[:q])
      expect(a_request(:get, search_url).with(query: params)).to have_been_made
    end

    it 'should offset to be specified without limit' do
      params = { q: 'foo bar baz', offset: 31, limit: 20, include: '' }
      search_url = stub_metatron_request(request_id, params)
      expect(Talis::Bibliography::Work).to receive(:token).and_return('foobar')
      Talis::Bibliography::Work.find(request_id: request_id, query: params[:q],
                                     opts: { offset: 31 })
      expect(a_request(:get, search_url).with(query: params)).to have_been_made
    end

    it 'should limit to be specified without offset' do
      params = { q: 'foo bar baz', offset: 0, limit: 13, include: '' }
      search_url = stub_metatron_request(request_id, params)
      expect(Talis::Bibliography::Work).to receive(:token).and_return('foobar')
      Talis::Bibliography::Work.find(request_id: request_id, query: params[:q],
                                     opts: { limit: 13 })
      expect(a_request(:get, search_url).with(query: params)).to have_been_made
    end

    it 'should both offset and limit to be specified' do
      params = { q: 'foo bar baz', offset: 31, limit: 13, include: '' }
      search_url = stub_metatron_request(request_id, params)
      expect(Talis::Bibliography::Work).to receive(:token).and_return('foobar')

      Talis::Bibliography::Work.find(request_id: request_id, query: params[:q],
                                     opts: { offset: 31, limit: 13 })
      expect(a_request(:get, search_url).with(query: params)).to have_been_made
    end

    it 'should allow include to be specified' do
      params = { q: 'foo bar baz', offset: 0, limit: 20,
                 include: 'manifestations.assets' }
      search_url = stub_metatron_request(request_id, params)
      expect(Talis::Bibliography::Work).to receive(:token).and_return('foobar')
      Talis::Bibliography::Work.find(request_id: request_id, query: params[:q],
                                     include: ['manifestations.assets'])
      expect(a_request(:get, search_url).with(query: params)).to have_been_made
    end

    it 'should accept and pass all supplied options' do
      params = { q: '\:foo\:', offset: 10, limit: 50,
                 include: 'manifestations.assets' }
      search_url = stub_metatron_request(request_id, params)
      expect(Talis::Bibliography::Work).to receive(:token).and_return('foobar')
      Talis::Bibliography::Work.find(request_id: request_id, query: ':foo:',
                                     include: ['manifestations.assets'],
                                     opts: { offset: 10, limit: 50,
                                             escape_query: true })
      expect(a_request(:get, search_url).with(query: params)).to have_been_made
    end
  end

  def stub_metatron_request(request_id, params)
    url = stub_url
    stub_request(:get, url).with(headers: request_headers(request_id),
                                 query: params)
                           .to_return(status: 200, body: empty_result_body,
                                      headers: {})
    url
  end

  def stub_url
    url = Talis::Bibliography::Work.base_uri
    base_path = if ENV['METATRON_BASE_PATH']
                  "#{ENV['METATRON_BASE_PATH']}/works"
                else
                  '/2/works'
                end

    url << base_path unless url.match(base_path)
    url
  end

  def empty_result_body
    '{ "meta": { "count": 0, "offset": 0, "limit": 20 }, "data": [] }'
  end

  def request_headers(request_id)
    { 'Accept' => 'application/vnd.api+json',
      'Authorization' => 'Bearer ',
      'Content-Type' => 'application/json',
      'X-Request-Id' => request_id }
  end
end
