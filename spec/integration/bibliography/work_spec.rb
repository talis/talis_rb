require_relative '../spec_helper'

describe Talis::Bibliography::Work do
  before do
    Talis::Authentication::Token.base_uri(persona_base_uri)
    Talis::Authentication.client_id = client_id
    Talis::Authentication.client_secret = client_secret
    Talis::Bibliography::Work.base_uri(metatron_base_uri)
  end

  context 'searching works' do
    it 'returns works when given a valid query' do
      works = Talis::Bibliography::Work.find(query: 'rockclimbing',
                                             opts: { offset: 0, limit: 1 })
      expect(works).to be_a(MetatronClient::WorkResultSet)
      expect(works.first).to be_a(Talis::Bibliography::Work)
      expect(works.first).to eq works.data.first
      expect(works.meta.limit).to eq 1
    end

    it 'hydrates manifestations when they are included' do
      works = Talis::Bibliography::Work.find(query: 'rockclimbing',
                                             opts: { offset: 0, limit: 1 },
                                             include: ['manifestations'])
      expect(works).to be_a(MetatronClient::WorkResultSet)
      expect(works.first).to be_a(Talis::Bibliography::Work)
      expect(works.first.manifestations).not_to be_empty
      expect(works.first.manifestations.first)
        .to be_a(Talis::Bibliography::Manifestation)
      expect(works.first.assets).to be_empty
    end

    it 'hydrates assets when they are included' do
      works = Talis::Bibliography::Work.find(
        query: 'rockclimbing', opts: { offset: 0, limit: 1 },
        include: ['manifestations.assets']
      )
      expect(works).to be_a(MetatronClient::WorkResultSet)
      expect(works.last).to be_a(Talis::Bibliography::Work)
      expect(works.last.manifestations).not_to be_empty
      expect(works.last.manifestations.first)
        .to be_a(Talis::Bibliography::Manifestation)
      expect(works.last.assets).not_to be_empty
      expect(works.last.assets.first).to be_a(MetatronClient::AssetData)
    end

    it 'should return an empty WorkResult if there are no query matches' do
      works = Talis::Bibliography::Work.find(query: 'hicvnafih',
                                             opts: { offset: 0, limit: 1 })
      expect(works).to be_a(MetatronClient::WorkResultSet)
      expect(works.data).to be_empty
      expect(works.meta.count).to eq 0
      expect(works.meta.offset).to eq 0
      expect(works.meta.limit).to eq 1
    end

    it 'should fail when query terms contain unescaped reserved characters' do
      queries = ["Don't make me think!", 'Pl/SQL', '{some query', 'some query}',
                 '[foobar]', 'the~tenticle', 'have you seen my ^', ':foo:',
                 '(some query', 'some query)', '"some query']
      queries.each do |query|
        expect do
          Talis::Bibliography::Work.find(query: query,
                                         opts: { offset: 0, limit: 1 })
        end.to raise_error(Talis::BadRequestError)
      end
    end

    it 'should return a ResultSet when reserved characters are escaped' do
      queries = ["Don't make me think!", 'Pl/SQL', '{some query', 'some query}',
                 '[foobar]', 'the~tenticle', 'have you seen my ^', ':foo:',
                 '(some query', 'some query)', '"some query']
      queries.each do |query|
        works = Talis::Bibliography::Work.find(query: query,
                                               opts: { offset: 0, limit: 1,
                                                       escape_query: true })
        expect(works).to be_a(MetatronClient::WorkResultSet)
        expect(works).to be_a(Talis::Bibliography::ResultSet)
      end
    end
  end
end
