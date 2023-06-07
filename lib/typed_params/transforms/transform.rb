# frozen_string_literal: true

module TypedParams
  module Transforms
    class Transform
      def call(key, value) = raise NotImplementedError

      def self.wrap(fn) = fn
    end
  end
end
