# frozen_string_literal: true

require 'typed_parameters/transforms/transform'

module TypedParameters
  module Transforms
    class KeyAlias < Transform
      def initialize(as) = @as = as
      def call(_, value) = [as, value]

      private

      attr_reader :as
    end
  end
end
