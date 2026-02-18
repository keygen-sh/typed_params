# frozen_string_literal: true

require 'typed_params/transforms/transform'

module TypedParams
  module Transforms
    class NilifyBlanks < Transform
      def call(param)
        return if
          param.value.is_a?(Array) || param.value.is_a?(Hash)

        param.value = nil if param.value.blank?
      end
    end
  end
end
