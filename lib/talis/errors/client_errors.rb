module Talis
  class ClientError < Talis::Error
  end

  class NotFoundError < ClientError
  end
end
