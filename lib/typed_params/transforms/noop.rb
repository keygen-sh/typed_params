# frozen_string_literal: true

require 'typed_params/transforms/transform'

module TypedParams
  module Transforms
    class Noop < Transform
      def call(param)
        param.delete
      end
    end
  end
end
