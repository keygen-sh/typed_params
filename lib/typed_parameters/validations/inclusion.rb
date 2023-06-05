# frozen_string_literal: true

require 'typed_parameters/validations/validation'

module TypedParameters
  module Validations
    class Inclusion < Validation
      def call(value)
        raise ValidationError, 'is invalid' unless
          case options
          in in: Range | Array => e
            e.include?(value)
          end
      end
    end
  end
end
