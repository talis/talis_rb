require_relative 'spec_helper'

describe Talis::Analytics do
  describe 'sending events' do
    before do
      Talis::Authentication::Token.base_uri(persona_base_uri)
      Talis::Analytics::Event.base_uri(echo_base_uri)
      Talis::Authentication.client_id = client_id
      Talis::Authentication.client_secret = client_secret

      @object = Object.new
      @object.extend(Talis::Analytics)
    end

    context 'successfully' do
      it 'should be able to send an event providing at least class & source' do
        event = {
          class: 'test.event',
          source: 'talis_rb.build'
        }

        @object.send_analytics_event event

        expect(a_request(:post, "#{echo_base_uri}/1/events").with do |request|
                 request.body == [event].to_json
               end).to have_been_made
      end

      it 'should be able to send an event with all optional attributes' do
        event = {
          class: 'test.event',
          source: 'talis_rb.build',
          user: 'fdgNy6QWGmIAl7BRjEsFtA',
          timestamp: Time.new(2016).to_i,
          props: {
            type: 'test-data'
          }
        }

        @object.send_analytics_event event

        expect(a_request(:post, "#{echo_base_uri}/1/events").with do |request|
          request.body == [event].to_json
        end).to have_been_made
      end
    end

    context 'validating data' do
      it 'should reject an event object without at least class and source' do
        event = {}

        expect { @object.send_analytics_event event }.to(
          raise_error(ArgumentError, 'event must contain class and source')
        )

        expect(a_request(:post, "#{echo_base_uri}/1/events"))
          .not_to have_been_made
      end

      it 'should white list event data' do
        timestamp = Time.new(2016).to_i
        expected_body = [
          class: 'test.event',
          source: 'talis_rb.build',
          user: 'fdgNy6QWGmIAl7BRjEsFtA',
          timestamp: timestamp,
          props: {
            type: 'test-data'
          }
        ].to_json

        event = {
          class: 'test.event',
          source: 'talis_rb.build',
          user: 'fdgNy6QWGmIAl7BRjEsFtA',
          timestamp: timestamp,
          props: {
            type: 'test-data'
          },
          invalid_attr: 'blah',
          invalid_hash: {
            invalid_key: 'de blah'
          }
        }

        @object.send_analytics_event event

        expect(a_request(:post, "#{echo_base_uri}/1/events").with do |request|
          request.body == expected_body
        end).to have_been_made
      end
    end

    context 'unsuccessfully' do
      let(:event) { { class: 'test.event', source: 'talis_rb.build' } }

      it 'raises an error when the server responds with a bad request error' do
        stub_request(:post, "#{echo_base_uri}/1/events").to_return(
          status: [400]
        )

        expect { @object.send_analytics_event event }.to(
          raise_error(Talis::BadRequestError)
        )
      end

      it 'raises an error when the server responds with a server error' do
        stub_request(:post, "#{echo_base_uri}/1/events").to_return(
          status: [500]
        )

        expect { @object.send_analytics_event event }.to(
          raise_error(Talis::ServerError)
        )
      end

      it 'raises an error when there is a problem talking to the server' do
        Talis::Analytics::Event.base_uri('http://foo')

        expect { @object.send_analytics_event event }.to(
          raise_error(Talis::ServerCommunicationError)
        )
      end

      it 'raises an error when the client credentials are invalid' do
        Talis::Authentication.client_id = 'ruby-client-test'
        Talis::Authentication.client_secret = 'ruby-client-test'

        message = 'The client credentials are invalid'

        expect { @object.send_analytics_event event }.to(
          raise_error(Talis::BadRequestError, message)
        )
      end
    end
  end
end
