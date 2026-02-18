# frozen_string_literal: true

module TypedParams
  module Validations
    class Validation
      def initialize(options) = @options = options
      def call(value)         = raise NotImplementedError

      # wraps a callable e.g. Proc for use as a Validation
      def self.wrap(fn)
        return fn if fn in Validation

        Wrapped.new(fn)
      end

      private

      attr_reader :options
    end
  end
end
