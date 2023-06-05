# frozen_string_literal: true

require 'typed_parameters/transforms/transform'

module TypedParameters
  module Transforms
    class Noop < Transform
      def call(*) = []
    end
  end
end
