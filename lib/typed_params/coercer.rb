# frozen_string_literal: true

require 'typed_params/mapper'

module TypedParams
  class Coercer < Mapper
    def call(params)
      depth_first_map(params) do |param|
        schema = param.schema
        next unless
          schema.coerce?

        param.value = schema.type.coerce(param.value)
      rescue CoercionError
        type = Types.for(param.value)

        raise InvalidParameterError.new("failed to coerce #{type} to #{schema.type}", path: param.path, source: schema.source)
      end
    end
  end
end
