# frozen_string_literal: true

require 'typed_params/transforms/transform'

module TypedParams
  module Transforms
    class Collapse < Transform
      DEFAULT_FORMAT = :parent_child

      def initialize(options)
        @format = case options
                  in format: :parent_child | :child_parent | :child => format
                    format
                  in Proc => transformer
                    transformer
                  in true
                    DEFAULT_FORMAT
                  end
      end

      def call(param)
        return unless
          param.hash? && param.parent?

        parent = param.parent

        param.values.each do |child|
          key, value = transform(param.key, param.value, child.key, child.value)

          child.key   = key
          child.value = value

          parent[key] = child # move up
        end

        param.delete
      end

      private

      attr_reader :format

      def transform(parent_key, parent_value, child_key, child_value)
        case format
        in Proc
          format.call(parent_key, parent_value, child_key, child_value)
        in :parent_child
          [:"#{parent_key}_#{child_key}", child_value]
        in :child_parent
          [:"#{child_key}_#{parent_key}", child_value]
        in :child
          [child_key, child_value]
        end
      end
    end
  end
end
