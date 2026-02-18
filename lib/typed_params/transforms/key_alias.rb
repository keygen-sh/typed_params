# frozen_string_literal: true

require 'typed_params/transforms/transform'

module TypedParams
  module Transforms
    class KeyAlias < Transform
      def initialize(key) = @key = key

      def call(param)
        param.key = key
      end

      private

      attr_reader :key
    end
  end
end
