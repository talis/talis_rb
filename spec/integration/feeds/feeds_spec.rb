require_relative '../spec_helper'

describe Talis::Feeds::Feed do
  let(:guid) { ENV.fetch('TEST_USER_GUID', 'fdgNy6QWGmIAl7BRjEsFtA') }

  before do
    Talis::Authentication::Token.base_uri(persona_base_uri)
    Talis::Authentication.client_id = client_id
    Talis::Authentication.client_secret = client_secret
    Talis::Feeds::Annotation.base_uri(babel_base_uri)
    Talis::Feeds::Feed.base_uri(babel_base_uri)
  end

  describe 'Retrieving feeds' do
    context 'successfully' do
      before do
        @target_uri = "http://test.talis.com/#{rand(0...9999)}"
        @md5_target_uri = Digest::MD5.hexdigest(@target_uri)

        opts = {
          body: { format: 'text/plain', type: 'Text', chars: 'Test Comment' },
          target: [{ uri: @target_uri }],
          annotated_by: 'test_ruby_client',
          expires_at: 1.hour.from_now.utc.iso8601(3)
        }
        @annotation = Talis::Feeds::Annotation.create(opts)
      end

      it 'retrieves a hydrated feed by target URI using the babel API' do
        Talis::Feeds::Feed.find(target_uri: @target_uri)

        url = "#{babel_base_uri}/feeds/targets/#{@md5_target_uri}/activity/"\
              'annotations/hydrate'
        expect(a_request(:get, url))
          .to have_been_made
      end

      it 'returns an array of annotations upon receiving a response' do
        # Babel processes annotations asynchronously so we will get 404s
        # until the job to persist the annotation has completed.
        wait_for { Talis::Feeds::Feed.find(target_uri: @target_uri) }
          .not_to be_empty

        annotations = Talis::Feeds::Feed.find(target_uri: @target_uri)

        expect(annotations.size).to be 1
        annotation = annotations.first
        expect(annotation.id).to eq @annotation.id
      end

      it 'hydrates users within annotations' do
        target_uri = "http://test.talis.com/#{rand(0...999)}"

        opts = {
          body: { format: 'text/plain', type: 'Text', chars: 'Test Hydration' },
          target: [{ uri: target_uri }],
          annotated_by: guid,
          expires_at: 1.hour.from_now.utc.iso8601(3)
        }
        Talis::Feeds::Annotation.create(opts)

        wait_for { Talis::Feeds::Feed.find(target_uri: target_uri) }
          .not_to be_empty

        annotation = Talis::Feeds::Feed.find(target_uri: target_uri).first
        user = annotation.user

        expect(user).to be_a Talis::User
        expect(user.guid).to eq guid
        expect(user.first_name).not_to be_nil
        expect(user.surname).not_to be_nil
        expect(user.email).not_to be_nil
      end

      it 'does not hydrate unknown users within annotations' do
        # Append an annotation with a recognised user on top of the unknown one.
        opts = {
          body: { format: 'text/plain', type: 'Text', chars: 'Test Hydration' },
          target: [{ uri: @target_uri }],
          annotated_by: guid,
          expires_at: 1.hour.from_now.utc.iso8601(3)
        }
        Talis::Feeds::Annotation.create(opts)

        wait_for { Talis::Feeds::Feed.find(target_uri: @target_uri) }
          .not_to be_empty

        # Grab the annotation with the unknown user, it will not be
        # available for hydration.
        annotation = Talis::Feeds::Feed.find(target_uri: @target_uri).last

        expect(annotation.user).to be_nil
      end

      it 'returns an empty array when the feed is not found' do
        annotations = Talis::Feeds::Feed.find(target_uri: 'not_found')

        expect(annotations.size).to be 0
      end
    end

    context 'unsuccessfully' do
      let(:url) do
        md5_target_uri = Digest::MD5.hexdigest('dummy_uri')
        "#{babel_base_uri}/feeds/targets/#{md5_target_uri}/activity/"\
        'annotations/hydrate'
      end

      it 'raises an error when the server responds with a bad request error' do
        stub_request(:get, url).to_return(
          status: [400]
        )

        expect { Talis::Feeds::Feed.find(target_uri: 'dummy_uri') }.to(
          raise_error(Talis::BadRequestError)
        )
      end

      it 'raises an error when the server responds with a server error' do
        stub_request(:get, url).to_return(
          status: [500]
        )

        expect { Talis::Feeds::Feed.find(target_uri: 'dummy_uri') }.to(
          raise_error(Talis::ServerError)
        )
      end

      it 'raises an error when there is a problem talking to the server' do
        Talis::Feeds::Feed.base_uri('http://foo')

        expect { Talis::Feeds::Feed.find(target_uri: 'dummy_uri') }.to(
          raise_error(Talis::ServerCommunicationError)
        )
      end

      it 'raises an error when the client credentials are invalid' do
        Talis::Authentication.client_id = 'ruby-client-test'
        Talis::Authentication.client_secret = 'ruby-client-test'

        message = 'The client credentials are invalid'

        expect { Talis::Feeds::Feed.find(target_uri: 'dummy_uri') }.to(
          raise_error(Talis::BadRequestError, message)
        )
      end
    end
  end
end
