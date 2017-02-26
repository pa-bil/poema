module Poema
  module Exception
    class SignupActivationAlreadyActive < RuntimeError; end

    class NotFound < RuntimeError; end
    class AccessDenied < RuntimeError; end
    class AuthRequired < RuntimeError; end

    class SortUnknownOption < RuntimeError; end
  end
end
