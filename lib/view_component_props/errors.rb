# frozen_string_literal: true

module ViewComponentProps
  class Error < StandardError; end

  class UnknownOptionError < Error; end
  class UnknownCastError < Error; end
  class CastError < Error; end
  class RequiredPropError < Error; end
  class InvalidEnumValueError < Error; end
  class ValidationFailedError < Error; end
  class UnknownPropsError < Error; end
end
