# frozen_string_literal: true

require 'typed_parameters/validations/validation'

module TypedParameters
  module Validations
    class Exclusion < Validation
      def call(value)
        raise ValidationError, 'is invalid' if
          case options
          in in: Range | Array => e
            e.include?(value)
          end
      end
    end
  end
end
