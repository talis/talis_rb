require_relative '../spec_helper'

describe Talis::Bibliography::Work do
  let(:request_id) { 'request-id-123' }
  context 'escaping works search queries' do
    it 'should not escape reserved characters in query by default' do
      query = '"/the + quick - brown: = fo\x && jumps || {over} > the <' \
        ' (lazy) ~ dog?!'
      allow(Talis::Bibliography::Work).to receive(:search_works).with(
        request_id, query, 0, 20, []
      )
      Talis::Bibliography::Work.find(request_id: request_id, query: query)
    end

    it 'should escape reserved characters if requested' do
      query = '"/the + quick - brown: = fo\x && jumps || {over} > the <' \
        ' (lazy) ~ dog?!'
      expected_query = '\"\/the \+ quick \- brown\: \= fo\\\x \&& jumps \||' \
        ' \{over\} \> the \< \(lazy\) \~ dog\?\!'
      allow(Talis::Bibliography::Work).to receive(:search_works).with(
        request_id, expected_query, 0, 20, []
      )
      Talis::Bibliography::Work.find(request_id: request_id, query: query,
                                     include: [], opts: { escape_query: true })
    end
  end

  context 'passing search options' do
    it 'should set defaults for includes, offset, and limit' do
      query = 'foo bar baz'
      allow(Talis::Bibliography::Work).to receive(:search_works).with(
        request_id, query, 0, 20, []
      )
      Talis::Bibliography::Work.find(request_id: request_id, query: query)
    end

    it 'should offset to be specified without limit' do
      query = 'foo bar baz'
      allow(Talis::Bibliography::Work).to receive(:search_works).with(
        request_id, query, 31, 20, []
      )
      Talis::Bibliography::Work.find(request_id: request_id, query: query,
                                     opts: { offset: 31 })
    end

    it 'should limit to be specified without offset' do
      query = 'foo bar baz'
      allow(Talis::Bibliography::Work).to receive(:search_works).with(
        request_id, query, 0, 13, []
      )
      Talis::Bibliography::Work.find(request_id: request_id, query: query,
                                     opts: { limit: 13 })
    end

    it 'should both offset and limit to be specified' do
      query = 'foo bar baz'
      allow(Talis::Bibliography::Work).to receive(:search_works).with(
        request_id, query, 31, 13, []
      )
      Talis::Bibliography::Work.find(request_id: request_id, query: query,
                                     opts: { offset: 31, limit: 13 })
    end

    it 'should allow include to be specified' do
      query = 'foo bar baz'
      allow(Talis::Bibliography::Work).to receive(:search_works).with(
        request_id, query, 0, 20, ['manifestations.assets']
      )

      Talis::Bibliography::Work.find(request_id: request_id, query: query,
                                     include: ['manifestations.assets'])
    end

    it 'should accept and pass all supplied options' do
      allow(Talis::Bibliography::Work).to receive(:search_works).with(
        request_id, '\:foo\:', 10, 50, ['manifestations.assets']
      )

      Talis::Bibliography::Work.find(request_id: request_id, query: ':foo:',
                                     include: ['manifestations.assets'],
                                     opts: { offset: 10, limit: 50,
                                             escape_query: true })
    end
  end
end
