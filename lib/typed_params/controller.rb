# frozen_string_literal: true

require 'typed_params/handler'
require 'typed_params/handler_set'
require 'typed_params/schema_set'
require 'typed_params/memoize'

module TypedParams
  module Controller
    extend ActiveSupport::Concern

    included do
      include Memoize

      cattr_accessor :typed_handlers, default: HandlerSet.new
      cattr_accessor :typed_schemas,  default: SchemaSet.new

      memoize
      def typed_params(format: AUTO)
        handler = typed_handlers.params[self.class, action_name.to_sym]

        raise UndefinedActionError, "params have not been defined for action: #{action_name.inspect}" if
          handler.nil?

        schema    = handler.schema
        processor = Processor.new(controller: self, schema:)
        paramz    = Parameterizer.new(schema:)
        # TODO(ezekg) Add a config here that accepts a block, similar to a Rack app
        #             so that users can define their own parameter source. E.g.
        #             using and parsing request.body can allow array roots.
        params    = paramz.call(value: request.request_parameters.deep_symbolize_keys)
        formatter = case format
                    when Symbol, String
                      Formatters[format]
                    when AUTO
                      schema.formatter
                    else
                      nil
                    end

        processor.call(params)

        params.unwrap(
          controller: self,
          formatter:,
        )
      end

      memoize
      def typed_query(format: AUTO)
        handler = typed_handlers.query[self.class, action_name.to_sym]

        raise UndefinedActionError, "query has not been defined for action: #{action_name.inspect}" if
          handler.nil?

        schema    = handler.schema
        processor = Processor.new(controller: self, schema:)
        paramz    = Parameterizer.new(schema:)
        params    = paramz.call(value: request.query_parameters.deep_symbolize_keys)
        formatter = case format
                    when Symbol, String
                      Formatters[format]
                    when AUTO
                      schema.formatter
                    else
                      nil
                    end

        processor.call(params)

        params.unwrap(
          controller: self,
          formatter:,
        )
      end

      private

      def respond_to_missing?(method_name, *)
        return super unless
          /_(params|query)\z/.match?(method_name)

        name = controller_name&.classify&.underscore
        return super unless
          name.present?

        aliases = [
          :"#{name}_params",
          :"#{name}_query",
        ]

        aliases.include?(method_name) || super
      end

      def method_missing(method_name, ...)
        return super unless
          /_(params|query)\z/.match?(method_name)

        name = controller_name&.classify&.underscore
        return super unless
          name.present?

        case method_name
        when :"#{name}_params"
          typed_params(...)
        when :"#{name}_query"
          typed_query(...)
        else
          super
        end
      end
    end

    class_methods do
      def typed_params(on: nil, schema: nil, format: nil, **kwargs, &)
        schema = case schema
                 in Array(Symbol => namespace, Symbol => key)
                   typed_schemas[namespace, key] || raise(ArgumentError, "schema does not exist: #{namespace.inspect}/#{key.inspect}")
                 in Symbol => key
                   typed_schemas[self, key] || raise(ArgumentError, "schema does not exist: #{key.inspect}")
                 in nil
                   Schema.new(**kwargs, controller: self, source: :params, &)
                 end

        case on
        in Array => actions
          actions.each do |action|
            typed_handlers.params[self, action] = Handler.new(for: :params, action:, schema:, format:)
          end
        in Symbol => action
          typed_handlers.params[self, action] = Handler.new(for: :params, action:, schema:, format:)
        in nil
          typed_handlers.deferred << Handler.new(for: :params, schema:, format:)
        end
      end

      def typed_query(on: nil, schema: nil, **kwargs, &)
        schema = case schema
                 in Array(Symbol => namespace, Symbol => key)
                   typed_schemas[namespace, key] || raise(ArgumentError, "schema does not exist: #{namespace.inspect}/#{key.inspect}")
                 in Symbol => key
                   typed_schemas[self, key] || raise(ArgumentError, "schema does not exist: #{key.inspect}")
                 in nil
                   # FIXME(ezekg) Should query params :coerce by default?
                   Schema.new(nilify_blanks: true, strict: false, **kwargs, controller: self, source: :query, &)
                 end

        case on
        in Array => actions
          actions.each do |action|
            typed_handlers.query[self, action] = Handler.new(for: :query, action:, schema:)
          end
        in Symbol => action
          typed_handlers.query[self, action] = Handler.new(for: :query, action:, schema:)
        in nil
          typed_handlers.deferred << Handler.new(for: :query, schema:)
        end
      end

      def typed_schema(key, namespace: self, **kwargs, &)
        raise ArgumentError, "schema already exists: #{key.inspect}" if
          typed_schemas.exists?(namespace, key)

        typed_schemas[namespace, key] = Schema.new(**kwargs, controller: self, &)
      end

      private

      def method_added(method_name)
        return super unless
          typed_handlers.deferred?

        while handler = typed_handlers.deferred.shift
          handler.action = method_name

          case handler.for
          when :params
            typed_handlers.params[self, handler.action] = handler
          when :query
            typed_handlers.query[self, handler.action] = handler
          end
        end

        super
      end
    end

    def self.included(klass)
      raise ArgumentError, "cannot be used outside of controller (got #{klass.ancestors})" unless
        klass < ::ActionController::Metal

      super(klass)
    end
  end
end
