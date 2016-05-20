require_relative 'spec_helper'

describe Talis::User do
  let(:guid) { 'fdgNy6QWGmIAl7BRjEsFtA' }

  before do
    Talis::Authentication::Token.base_uri(persona_base_uri)
    Talis::User.base_uri(persona_base_uri)
    Talis::Authentication.client_id = client_id
    Talis::Authentication.client_secret = client_secret
  end

  context 'finding users' do
    it 'returns a single user by guid' do
      user = Talis::User.find(guid: guid)

      expect(user.is_a?(Talis::User)).to be true
      expect(user.guid).to eq guid
      expect(user.first_name).to eq 'TN'
      expect(user.surname).to eq 'TestAccount'
      expect(user.full_name).to eq 'TN TestAccount'
      expect(user.email).to eq 'test.tn@talis.com'
      expect(user.token).to be_nil
    end

    it 'returns a single user by gupid' do
      skip 'TODO'
    end

    it 'returns nil when a user is not found' do
      expect(Talis::User.find(guid: 'ruby-client-test')).to be_nil
    end

    it 'raises an error for all other error cases' do
      Talis::Authentication.client_id = 'ruby-client-test'
      Talis::Authentication.client_secret = 'ruby-client-test'

      expected_error = Talis::Errors::ClientError
      msg = 'The client credentials are invalid'

      expect { Talis::User.find(guid: guid) }.to raise_error expected_error, msg
    end
  end

  context 'fetching avatars' do
    let(:user) { Talis::User.find(guid: guid) }

    it 'returns an avatar image URL' do
      expected_url = "#{persona_base_uri}/users/#{guid}/avatar"

      expect(user.avatar_url).to eq expected_url
    end

    it 'returns an avatar image URL with a given size' do
      expected_url = "#{persona_base_uri}/users/#{guid}/avatar?size=50"

      expect(user.avatar_url(size: 50)).to eq expected_url
    end

    it 'returns an avatar image URL with a given colour' do
      url = "#{persona_base_uri}/users/#{guid}/avatar?colour=bab37b"

      expect(user.avatar_url(colour: 'bab37b')).to eq url
    end

    it 'returns an avatar image URL with a given size and colour' do
      url = "#{persona_base_uri}/users/#{guid}/avatar?size=60&colour=aba37b"

      expect(user.avatar_url(size: 60, colour: 'aba37b')).to eq url
    end
  end

  context 'updating users' do
    pending
  end

  context 'creating users' do
    pending
  end
end
