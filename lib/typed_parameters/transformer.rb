# frozen_string_literal: true

require 'typed_parameters/mapper'

module TypedParameters
  class Transformer < Mapper
    def call(params)
      depth_first_map(params) do |param|
        schema = param.schema
        parent = param.parent

        # Ignore nil optionals when config is enabled
        unless schema.allow_nil?
          if param.value.nil? && schema.optional? && TypedParameters.config.ignore_nil_optionals
            param.delete

            break
          end
        end

        schema.transforms.map do |transform|
          key, value = transform.call(param.key, param.value)
          if key.nil?
            param.delete

            break
          end

          # Check for nils again after transform
          unless schema.allow_nil?
            if value.nil? && schema.optional? && TypedParameters.config.ignore_nil_optionals
              param.delete

              break
            end
          end

          # If param's key has changed, we want to rename the key
          # for its parent too.
          if param.parent? && param.key != key
            parent[key] = param.delete
          end

          param.key, param.value = key, value
        end
      end
    end
  end
end
