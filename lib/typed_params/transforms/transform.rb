# frozen_string_literal: true

module TypedParams
  module Transforms
    class Transform
      def call(param) = raise NotImplementedError

      # wraps a callable e.g. Proc for use as a Transform
      def self.wrap(fn)
        return fn if fn in Transform

        Wrapped.new(fn)
      end
    end
  end
end
