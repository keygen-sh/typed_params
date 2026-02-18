# frozen_string_literal: true

require 'typed_params/validations/validation'

module TypedParams
  module Validations
    class Wrapped < Validation
      def initialize(fn) = @fn = fn

      def call(value)
        raise ValidationError, 'is invalid' unless fn.call(value)
      end

      private

      attr_reader :fn
    end
  end
end
