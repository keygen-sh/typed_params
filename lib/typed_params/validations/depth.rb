# frozen_string_literal: true

require 'typed_params/validations/validation'
require 'typed_params/path'

module TypedParams
  module Validations
    class Depth < Validation
      def call(value)
        case options
        in maximum: Integer => maximum_depth
          return if
            maximum_depth.nil? || maximum_depth == Float::INFINITY

          validate_depth!(value, maximum_depth:)
        end
      end

      private

      def validate_depth!(current_value, maximum_depth:, current_depth: 0, current_path: [])
        case current_value
        in Hash => hash
          hash.each do |key, value|
            path = current_path + [key]
            next if
              Types.scalar?(value)

            raise ValidationError.new("maximum depth of #{maximum_depth} exceeded", path: Path.new(*path)) if
              current_depth >= maximum_depth

            validate_depth!(value, maximum_depth:, current_depth: current_depth + 1, current_path: path)
          end
        in Array => arr
          arr.each_with_index do |value, index|
            path = current_path + [index]
            next if
              Types.scalar?(value)

            raise ValidationError.new("maximum depth of #{maximum_depth} exceeded", path: Path.new(*path)) if
              current_depth >= maximum_depth

            validate_depth!(value, maximum_depth:, current_depth: current_depth + 1, current_path: path)
          end
        else
          # TODO(ezekg) add support for custom types e.g. enumerables?
        end
      end
    end
  end
end
