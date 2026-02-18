# frozen_string_literal: true

require 'typed_params/transforms/transform'

module TypedParams
  module Transforms
    class Wrapped < Transform
      def initialize(fn) = @fn = fn

      def call(param)
        key, value = fn.call(param.key, param.value)
        if key.nil?
          param.delete # delete if transformed into nil

          return
        end

        param.key   = key unless key == param.key
        param.value = value
      end

      private

      attr_reader :fn
    end
  end
end
