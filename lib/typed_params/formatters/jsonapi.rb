# frozen_string_literal: true

require 'typed_params/formatters/formatter'

module TypedParams
  module Formatters
    ##
    # The JSONAPI formatter transforms a JSONAPI document into Rails'
    # standard params format that can be passed to a model.
    #
    # For example, given the following params:
    #
    #   {
    #     data: {
    #       type: 'users',
    #       id: '1',
    #       attributes: { email: 'foo@bar.example' },
    #       relationships: {
    #         friends: {
    #           data: [{ type: 'users', id: '2' }]
    #         }
    #       }
    #     }
    #   }
    #
    # The final params would become:
    #
    #   {
    #     id: '1',
    #     email: 'foo@bar.example',
    #     friend_ids: ['2']
    #   }
    #
    module JSONAPI
      def self.call(params, schema:)
        case params
        in data: Array => data
          child = schema.children.fetch(:data)

          format_array_data(data, schema: child)
        in data: Hash => data
          child = schema.children.fetch(:data)

          format_hash_data(data, schema: child)
        else
          params
        end
      end

      private

      def self.format_array_data(data, schema:)
        data.each_with_index.map do |value, i|
          child = schema.children.fetch(i) { schema.endless? ? schema.children.first : nil }

          format_hash_data(value, schema: child)
        end
      end

      def self.format_hash_data(data, schema:)
        rels  = data[:relationships]
        attrs = data[:attributes]
        res   = data.except(
          :attributes,
          :links,
          :meta,
          :relationships,
          :type,
        )

        # Move attributes over to top-level params
        attrs&.each do |key, attr|
          res[key] = attr
        end

        # Move relationships over. This will use x_id and x_ids when the
        # relationship data only contains :type and :id, otherwise it
        # will use the x_attributes key.
        rels&.each do |key, rel|
          child = schema.children.dig(:relationships, key)

          case rel
          # FIXME(ezekg) We need https://bugs.ruby-lang.org/issues/18961 to
          #              clean this up (i.e. remove the if guard).
          in data: [{ type:, id:, **nil }, *] => linkage if linkage.all? { _1 in type:, id:, **nil }
            res[:"#{key.to_s.singularize}_ids"] = linkage.map { _1[:id] }
          in data: []
            res[:"#{key.to_s.singularize}_ids"] = []
          # FIXME(ezekg) Not sure how to make this cleaner, but this handles polymorphic relationships.
          in data: { type:, id:, **nil } if key.to_s.underscore.classify != type.underscore.classify && child.polymorphic?
            res[:"#{key}_type"], res[:"#{key}_id"] = type.underscore.classify, id
          in data: { type:, id:, **nil }
            res[:"#{key}_id"] = id
          in data: nil
            res[:"#{key}_id"] = nil
          else
            # NOTE(ezekg) Embedded relationships are non-standard as per the
            #             JSONAPI spec, but I don't really care. :)
            res[:"#{key}_attributes"] = call(rel, schema: child)
          end
        end

        res
      end
    end

    register(:jsonapi,
      transform: JSONAPI.method(:call),
      decorate: -> {
        next if
          respond_to?(:typed_meta)

        mod = Module.new

        mod.define_method :respond_to_missing? do |method_name, *args|
          next super(method_name, *args) unless
            /_meta\z/.match?(method_name)

          name = controller_name&.classify&.underscore
          next super(method_name, *args) unless
            name.present?

          aliases = %I[
            #{name}_meta
            typed_meta
          ]

          aliases.include?(method_name) || super(method_name, *args)
        end

        mod.define_method :method_missing do |method_name, *args|
          next super(method_name, *args) unless
            /_meta\z/.match?(method_name)

          name = controller_name&.classify&.underscore
          next super(method_name, *args) unless
            name.present?

          case method_name
          when :"#{name}_meta",
               :typed_meta
            typed_params(format: nil).fetch(:meta) { {} }
          else
            super(method_name, *args)
          end
        end

        include mod
      },
    )
  end
end
