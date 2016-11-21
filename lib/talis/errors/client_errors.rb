module Talis
  class ClientError < Talis::Error
  end

  class BadRequestError < ClientError
  end

  class UnauthorizedError < ClientError
  end

  class ForbiddenError < ClientError
  end

  class NotFoundError < ClientError
  end

  class ConflictError < ClientError
  end
end
