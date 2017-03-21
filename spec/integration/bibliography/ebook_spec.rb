require_relative '../spec_helper'

describe Talis::Bibliography::EBook do
  before do
    Talis::Authentication::Token.base_uri(metatron_oauth_host)
    Talis::Bibliography::EBook.client_id = metatron_client_id
    Talis::Bibliography::EBook.client_secret = metatron_client_secret
    Talis::Bibliography::EBook.base_uri(metatron_base_uri)
  end

  context 'finding ebooks by manifestation' do
    it 'returns ebooks when given a valid manifestation ID' do
      id = '9781473915718'

      ebooks = Talis::Bibliography::EBook.find_by_manifestation_id(id)

      expect(ebooks.size).to eq 1
      ebook = ebooks.first
      expect(ebook).to be_a(Talis::Bibliography::EBook)

      expect(ebook.title).to eq 'An Introduction to Human Resource Management'
      expect(ebook.author).to eq 'Nick Wilton'
      expect(ebook.format).to eq 'ePub'
      expect(ebook.digital_list_price).to eq '58.00'
    end

    it 'can accept an NBD prefix' do
      id = 'nbd:9781473915718'

      ebooks = Talis::Bibliography::EBook.find_by_manifestation_id(id)

      expect(ebooks.size).to eq 1
    end

    it 'returns an empty array when given a manifestation with no assets' do
      id = 'nbd:9781280657023'

      ebooks = Talis::Bibliography::EBook.find_by_manifestation_id(id)

      expect(ebooks.size).to eq 0
    end

    it 'handles a missing data' do
      id = '9781473915718'

      stub_request(:get, %r{2/manifestations/#{id}/assets}).to_return(
        status: [200],
        headers: { 'Content-Type' => 'application/json' },
        body: JSON.generate(data: [
                              {
                                id: 'sku:9781473966116',
                                type: 'ebook_inventory'
                              }
                            ])
      )

      ebooks = Talis::Bibliography::EBook.find_by_manifestation_id(id)

      expect(ebooks.size).to eq 1
      ebook = ebooks.first
      expect(ebook).to be_a(Talis::Bibliography::EBook)

      expect(ebook.title).to be_nil
      expect(ebook.author).to be_nil
      expect(ebook.format).to be_nil
      expect(ebook.digital_list_price).to be_nil
    end

    it 'does not include non-ebook assets' do
      id = '9781473915718'

      stub_request(:get, %r{2/manifestations/#{id}/assets}).to_return(
        status: [200],
        headers: { 'Content-Type' => 'application/json' },
        body: JSON.generate(data: [
                              {
                                id: 'sku:9781473966116',
                                type: 'something_else'
                              }
                            ])
      )

      ebooks = Talis::Bibliography::EBook.find_by_manifestation_id(id)

      expect(ebooks.size).to eq 0
    end

    it 'raises an error when the server responds with a bad request error' do
      stub_request(:get, %r{2/manifestations/:nbd/assets}).to_return(
        status: [400]
      )

      expected_error = Talis::BadRequestError

      expect { Talis::Bibliography::EBook.find_by_manifestation_id(':nbd') }.to(
        raise_error expected_error)
    end

    it 'raises an error when the server responds with a server error' do
      stub_request(:get, %r{2/manifestations/123/assets}).to_return(
        status: [500]
      )

      expected_error = Talis::ServerError

      expect { Talis::Bibliography::EBook.find_by_manifestation_id('123') }.to(
        raise_error expected_error)
    end

    it 'raises an error when there is a problem talking to the server' do
      Talis::Bibliography::EBook.base_uri('http://foo')

      expected_error = Talis::ServerCommunicationError

      expect { Talis::Bibliography::EBook.find_by_manifestation_id('456') }.to(
        raise_error expected_error)
    end

    it 'raises an error when the client credentials are invalid' do
      Talis::Bibliography::EBook.client_id = 'ruby-client-test'
      Talis::Bibliography::EBook.client_secret = 'ruby-client-test'

      error = Talis::BadRequestError
      msg = 'The client credentials are invalid'

      expect { Talis::Bibliography::EBook.find_by_manifestation_id('789') }.to(
        raise_error(error, msg))
    end
  end

  context 'finding ebooks by work' do
    pending 'TODO: https://github.com/talis/platform/issues/775'
  end
end
