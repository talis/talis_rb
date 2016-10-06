module Talis
  # All errors will extend from this base class.
  class Error < StandardError
  end
end

require_relative 'errors/authentication_failed_error'
require_relative 'errors/client_errors'
require_relative 'errors/server_error'
require_relative 'errors/server_communication_error'
