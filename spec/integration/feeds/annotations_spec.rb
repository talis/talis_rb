require_relative '../spec_helper'

describe Talis::Feeds::Annotation do
  before do
    Talis::Authentication::Token.base_uri(persona_base_uri)
    Talis::Authentication.client_id = client_id
    Talis::Authentication.client_secret = client_secret
    Talis::Feeds::Annotation.base_uri(babel_base_uri)
  end

  describe 'Creating annotations' do
    context 'successfully' do
      it 'posts an annotation using the babel API' do
        opts = {
          body: { format: 'text/plain', type: 'Text' },
          target: [{ uri: 'http://test.talis.com' }],
          annotated_by: 'test_ruby_client',
          expires_at: 1.hour.from_now.utc.iso8601(3)
        }

        Talis::Feeds::Annotation.create(opts)

        expect(a_request(:post, "#{babel_base_uri}/annotations"))
          .to have_been_made
      end

      it 'returns a created annotation upon receiving a response' do
        opts = {
          body: { format: 'text/plain', type: 'Text' },
          target: [{ uri: 'http://test.talis.com' }],
          annotated_by: 'test_ruby_client',
          expires_at: 1.hour.from_now.utc.iso8601(3)
        }
        annotation = Talis::Feeds::Annotation.create(opts)

        expect(annotation).to be_a Talis::Feeds::Annotation
        expect(annotation.id).not_to be_nil
      end

      it 'allows all valid properties to be sent' do
        opts = {
          body: {
            format: 'text/plain',
            type: 'Text',
            chars: 'Test Comment',
            details: { foo: 'bar' }
          },
          target: [{
            uri: 'http://test.talis.com',
            as_referenced_by: 'http://videos.talis.com',
            fragment: 't=npt:0,5'
          }],
          annotated_by: 'test_ruby_client',
          motivated_by: 'commenting',
          expires_at: 1.hour.from_now.utc.iso8601(3)
        }

        annotation = Talis::Feeds::Annotation.create(opts)

        expect(annotation.body).to eq opts[:body]
        expect(annotation.target).to eq opts[:target]
        expect(annotation.annotated_by).to eq opts[:annotated_by]
        expect(annotation.motivated_by).to eq opts[:motivated_by]
        expect(annotation.expires_at).to eq opts[:expires_at]
      end

      it 'supports multiple targets' do
        opts = {
          body: { format: 'text/plain', type: 'Text' },
          target: [
            { uri: 'http://test.talis.com' },
            { uri: 'http://another-test.talis.com' }
          ],
          annotated_by: 'test_ruby_client',
          expires_at: 1.hour.from_now.utc.iso8601(3)
        }

        annotation = Talis::Feeds::Annotation.create(opts)

        expect(annotation.target).to eq opts[:target]
      end
    end

    context 'validating data' do
      it 'should raise an error when the minimum args are not provided' do
        message = 'annotation must contain body, target and annotated_by'

        expect { Talis::Feeds::Annotation.create({}) }.to(
          raise_error(ArgumentError, message)
        )

        expect(a_request(:post, "#{babel_base_uri}/annotations"))
          .not_to have_been_made
      end

      it 'should raise an error when the target has no URI' do
        opts = {
          body: { format: 'text/plain', type: 'Text' },
          target: [{ invalid: 'http://test.talis.com' }],
          annotated_by: 'test_ruby_client'
        }

        message = 'annotation targets must contain uri'

        expect { Talis::Feeds::Annotation.create(opts) }.to(
          raise_error(ArgumentError, message)
        )
      end

      it 'should raise an error when the target is not an array' do
        opts = {
          body: { format: 'text/plain', type: 'Text' },
          target: { uri: 'http://test.talis.com' },
          annotated_by: 'test_ruby_client'
        }

        message = 'annotation target must be an array'

        expect { Talis::Feeds::Annotation.create(opts) }.to(
          raise_error(ArgumentError, message)
        )
      end

      it 'should raise an error when any target URI is not a string' do
        opts = {
          body: { format: 'text/plain', type: 'Text' },
          target: [
            { uri: 'http://test.talis.com' },
            { uri: -1 }
          ],
          annotated_by: 'test_ruby_client'
        }

        message = 'target uri must be a string'

        expect { Talis::Feeds::Annotation.create(opts) }.to(
          raise_error(ArgumentError, message)
        )
      end

      it 'should raise an error when the expiry time is invalid' do
        opts = {
          body: { format: 'text/plain', type: 'Text' },
          target: [{ uri: 'http://test.talis.com' }],
          annotated_by: 'test_ruby_client',
          expires_at: -1
        }

        message = 'expired_at must be a valid ISO 8601 date'

        expect { Talis::Feeds::Annotation.create(opts) }.to(
          raise_error(ArgumentError, message)
        )
      end
    end

    context 'unsuccessfully' do
      let(:good_opts) do
        {
          body: { format: 'text/plain', type: 'Text' },
          target: [{ uri: 'http://test.talis.com' }],
          annotated_by: 'test_ruby_client',
          expires_at: 1.hour.from_now.utc.iso8601(3)
        }
      end

      it 'raises an error when the server responds with a bad request error' do
        stub_request(:post, "#{babel_base_uri}/annotations").to_return(
          status: [400]
        )

        expect { Talis::Feeds::Annotation.create(good_opts) }.to(
          raise_error(Talis::BadRequestError)
        )
      end

      it 'raises an error when the server responds with a server error' do
        stub_request(:post, "#{babel_base_uri}/annotations").to_return(
          status: [500]
        )

        expect { Talis::Feeds::Annotation.create(good_opts) }.to(
          raise_error(Talis::ServerError)
        )
      end

      it 'raises an error when there is a problem talking to the server' do
        Talis::Feeds::Annotation.base_uri('http://foo')

        expect { Talis::Feeds::Annotation.create(good_opts) }.to(
          raise_error(Talis::ServerCommunicationError)
        )
      end

      it 'raises an error when the client credentials are invalid' do
        Talis::Authentication.client_id = 'ruby-client-test'
        Talis::Authentication.client_secret = 'ruby-client-test'

        message = 'The client credentials are invalid'

        expect { Talis::Feeds::Annotation.create(good_opts) }.to(
          raise_error(Talis::BadRequestError, message)
        )
      end
    end
  end
end
