# frozen_string_literal: true

require 'typed_parameters/transforms/transform'

module TypedParameters
  module Transforms
    class NilifyBlanks < Transform
      def call(key, value)
        return [key, value] if
          value.is_a?(Array) || value.is_a?(Hash)

        [key, value.blank? ? nil : value]
      end
    end
  end
end
