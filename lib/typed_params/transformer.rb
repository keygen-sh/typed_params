# frozen_string_literal: true

require 'typed_params/mapper'

module TypedParams
  class Transformer < Mapper
    def call(params)
      depth_first_map(params) do |param|
        schema = param.schema

        # Ignore nil optionals when config is enabled
        unless schema.allow_nil?
          if param.value.nil? && schema.optional? && TypedParams.config.ignore_nil_optionals
            param.delete

            break
          end
        end

        schema.transforms.each do |transform|
          transform.call(param)
          break if
            param.deleted?

          # Check for nils again after transform
          unless schema.allow_nil?
            if param.value.nil? && schema.optional? && TypedParams.config.ignore_nil_optionals
              param.delete

              break
            end
          end
        end
      end
    end
  end
end
