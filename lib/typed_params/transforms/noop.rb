# frozen_string_literal: true

require 'typed_params/transforms/transform'

module TypedParams
  module Transforms
    class Noop < Transform
      def call(*) = []
    end
  end
end
