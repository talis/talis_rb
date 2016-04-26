module Talis
  module Errors
    class ClientError < StandardError
    end

    class NotFoundError < ClientError
    end
  end
end
