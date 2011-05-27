module Exceptions
	class UnsupportedOperation < Exception; end

  # Per HTTP Status Codes
	class HTTPBadRequest < Exception; end           # 400
	class HTTPUnauthorized < Exception; end         # 401
	class HTTPNotFound < Exception; end             # 404
	class HTTPInternalServerError < Exception; end  # 500

  # custom authorization
  class Unauthorized < Exception; end
end
