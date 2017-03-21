require_relative 'bibliography/result_set'
require_relative 'bibliography/work'
require_relative 'bibliography/manifestation'
require_relative 'bibliography/ebook'

module Talis
  # Encompasses all classes associated with bibliographic resources
  module Bibliography
    # Exposes the underlying Metatron API client.
    # @param request_id [String] ('uuid') unique ID for remote requests.
    # @return MetatronClient::DefaultApi
    def api_client(request_id = new_req_id)
      configure_metatron

      api_client = MetatronClient::ApiClient.new
      api_client.default_headers = {
        'X-Request-Id' => request_id,
        'User-Agent' => "talis-ruby-client/#{Talis::VERSION} "\
        "ruby/#{RUBY_VERSION}"
      }

      MetatronClient::DefaultApi.new(api_client)
    end

    private

    def configure_metatron
      MetatronClient.configure do |config|
        config.scheme = base_uri[/https?/]
        config.host = base_uri
        # Non-production environments have a base path
        if ENV['METATRON_BASE_PATH']
          config.base_path = ENV['METATRON_BASE_PATH']
        end
        config.api_key_prefix['Authorization'] = 'Bearer'
      end
    end

    def empty_result_set(klass, meta_properties)
      meta = OpenStruct.new(meta_properties)
      klass.new(data: [], meta: meta).extend(ResultSet)
    end

    def escape_query(query_string)
      # TODO: are all of these necessary?
      pattern = %r{
        (\+|\-|\=|\&\&|\|\||\>|\<|\!|\(|\)|\{|\}|\[|\]|\^|\"|\~|\*|\?|\:|\\|\/)
      }x
      query_string.gsub(pattern) { |match| "\\#{match}" }
    end
  end
end
