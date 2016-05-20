require_relative 'authentication/client'
require_relative 'authentication/token'
require_relative 'authentication/login'

module Talis
  # Encompasses all classes associated with user authentication
  module Authentication
    # The ID of the OAuth client to allow requests for asset resources.
    cattr_accessor :client_id
    # The secret of the OAuth client to allow requests for asset resources.
    cattr_accessor :client_secret
  end
end
