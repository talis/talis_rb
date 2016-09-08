require_relative '../spec_helper'

describe Talis::Bibliography::Manifestation do
  before do
    Talis::Authentication::Token.base_uri(persona_base_uri)
    Talis::Authentication.client_id = client_id
    Talis::Authentication.client_secret = client_secret
    Talis::Bibliography::Manifestation.base_uri(metatron_base_uri)
  end

  context 'searching manifestations' do
    it 'returns manifestations when given a valid isbn query' do
      books = Talis::Bibliography::Manifestation.find(
        opts: { isbn: '9785510816150' }
      )
      expect(books).to be_a(MetatronClient::ManifestationResultSet)
      expect(books.first).to be_a(Talis::Bibliography::Manifestation)
      expect(books.first).to eq books.data.first
      expect(books.meta.count).to eq 1
    end

    it 'returns manifestations when given a valid work_id query' do
      books = Talis::Bibliography::Manifestation.find(
          opts: { work_id: "amazon_web_services/russellj" }
      )
      expect(books).to be_a(MetatronClient::ManifestationResultSet)
      expect(books.first).to be_a(Talis::Bibliography::Manifestation)
      expect(books.first).to eq books.data.first
      expect(books.meta.count).to eq 1
    end

    it 'hydrates manifestations with included contributors' do
      book = Talis::Bibliography::Manifestation.find(
        opts: { isbn: '9785510816150' }
      ).first
      expect(book).to be_a(Talis::Bibliography::Manifestation)
      expect(book.contributors).to be_a(Array)
      expect(book.contributors.first).to be_a(MetatronClient::ResourceData)
      expect(book.contributors.first.type).to eq('agents')
      expect(book.contributors.first.attributes[:name]).to eq('Jesse Russell')
    end

    it 'hydrates manifestations with included work' do
      book = Talis::Bibliography::Manifestation.find(
        opts: { isbn: '9785510816150' }
      ).first
      expect(book).to be_a(Talis::Bibliography::Manifestation)
      expect(book.work).to be_a(MetatronClient::WorkData)
    end

    it 'should return an empty ManifestationResult if there are no matches' do
      books = Talis::Bibliography::Manifestation.find(
        opts: { isbn: '0123456789' }
      )
      expect(books).to be_a(MetatronClient::ManifestationResultSet)
      expect(books.data).to be_empty
      expect(books.meta.count).to eq 0
    end
  end
end
