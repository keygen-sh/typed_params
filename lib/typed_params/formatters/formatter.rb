# frozen_string_literal: true

module TypedParams
  module Formatters
    class Formatter
      attr_reader :decorator,
                  :format

      def initialize(format, transform:, decorate:)
        @format    = format
        @transform = transform
        @decorator = decorate
      end

      def decorator? = decorator.present?

      delegate :arity, :parameters, :call, to: :@transform
    end
  end
end
