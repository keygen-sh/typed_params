# frozen_string_literal: true

module TypedParams
  class Schema
    attr_reader :validations,
                :transforms,
                :formatter,
                :parent,
                :children,
                :source,
                :type,
                :key,
                :as,
                :alias,
                :if,
                :unless

    def initialize(
      controller: nil,
      source: nil,
      strict: true,
      parent: nil,
      type: :hash,
      key: nil,
      optional: false,
      coerce: false,
      polymorphic: false,
      allow_blank: false,
      allow_nil: false,
      allow_non_scalars: false,
      nilify_blanks: false,
      noop: false,
      inclusion: nil,
      exclusion: nil,
      format: nil,
      length: nil,
      transform: nil,
      validate: nil,
      if: nil,
      unless: nil,
      as: nil,
      alias: nil,
      casing: TypedParams.config.key_transform,
      &block
    )
      key ||= ROOT

      raise ArgumentError, 'key is required for child schema' if
        key == ROOT && parent.present?

      raise ArgumentError, 'root cannot be null' if
        key == ROOT && allow_nil

      raise ArgumentError, 'source must be one of: :params or :query' unless
        source.nil? || source == :params || source == :query

      raise ArgumentError, 'inclusion must be a hash with :in key' unless
        inclusion.nil? || inclusion.is_a?(Hash) && inclusion.key?(:in)

      raise ArgumentError, 'exclusion must be a hash with :in key' unless
        exclusion.nil? || exclusion.is_a?(Hash) && exclusion.key?(:in)

      raise ArgumentError, 'format must be a hash with :with or :without keys (but not both)' unless
        format.nil? || format.is_a?(Hash) && (
          format.key?(:with) ^
          format.key?(:without)
        )

      raise ArgumentError, 'length must be a hash with :minimum, :maximum, :within, :in, or :is keys (but not multiple except for :minimum and :maximum)' unless
        length.nil? || length.is_a?(Hash) && (
          length.key?(:minimum) && length.key?(:maximum) && length.size == 2 ||
            length.key?(:minimum) ^
            length.key?(:maximum) ^
            length.key?(:within) ^
            length.key?(:in) ^
            length.key?(:is)
        )

      @controller        = controller
      @source            = source
      @type              = Types[type]
      @strict            = strict
      @parent            = parent
      @key               = key
      @as                = as
      @alias             = binding.local_variable_get(:alias)
      @optional          = optional
      @coerce            = coerce && @type.coercable?
      @polymorphic       = polymorphic
      @allow_blank       = key == ROOT || allow_blank
      @allow_nil         = allow_nil
      @allow_non_scalars = allow_non_scalars
      @nilify_blanks     = nilify_blanks
      @noop              = noop
      @inclusion         = inclusion
      @exclusion         = exclusion
      @format            = format
      @length            = length
      @casing            = casing
      @transform         = transform
      @children          = nil
      @if                = binding.local_variable_get(:if)
      @unless            = binding.local_variable_get(:unless)
      @formatter         = nil
      @options           = {}

      # Validations
      @validations = []

      @validations << Validations::Inclusion.new(inclusion) if
        inclusion.present?

      @validations << Validations::Exclusion.new(exclusion) if
        exclusion.present?

      @validations << Validations::Format.new(format) if
        format.present?

      @validations << Validations::Length.new(length) if
        length.present?

      @validations << Validations::Validation.wrap(validate) if
        validate.present?

      # Transforms
      @transforms = []

      @transforms << Transforms::KeyAlias.new(as) if
        as.present?

      @transforms << Transforms::NilifyBlanks.new if
        nilify_blanks

      @transforms << Transforms::Transform.wrap(transform) if
        transform.present?

      @transforms << Transforms::KeyCasing.new(casing) if
        casing.present?

      @transforms << Transforms::Noop.new if
        noop

      raise ArgumentError, "type #{type} is a not registered type" if
        @type.nil?

      if block_given?
        raise ArgumentError, "type #{@type} does not accept a block" if
          @type.present? && !@type.accepts_block?

        @children = case
                    when Types.array?(@type)
                      []
                    when Types.hash?(@type)
                      {}
                    end

        self.instance_exec &block
      end
    end

    ##
    # format defines the final output format for the schema, transforming
    # the params from an input format to an output format, e.g. a JSONAPI
    # document to Rails' standard params format. This also applies the
    # formatter's decorators onto the controller.
    def format(format)
      raise NotImplementedError, 'cannot define format for child schema' if
        child?

      formatter = Formatters[format]

      raise ArgumentError, "invalid format: #{format.inspect}" if
        formatter.nil?

      # Apply the formatter's decorators onto the controller.
      controller.instance_exec(&formatter.decorator) if
        controller.present? && formatter.decorator?

      @formatter = formatter
    end

    ##
    # with defines a set of options to use for all direct children of the
    # schema defined within the block.
    #
    # For example, it can be used to define a common guard:
    #
    #   with if: -> { ... } do
    #     param :foo, type: :string
    #     param :bar, type: :string
    #     param :baz, type: :hash do
    #       param :qux, type: :string
    #     end
    #   end
    #
    # In this example, :foo, :bar, and :baz will inherit the if: guard,
    # but :qux will not, since it is not a direct child.
    #
    def with(**kwargs, &)
      orig     = @options
      @options = kwargs

      yield

      @options = orig
    end

    ##
    # param defines a keyed parameter for a hash schema.
    def param(key, type:, **kwargs, &block)
      raise NotImplementedError, "cannot define param for non-hash type (got #{self.type})" unless
        Types.hash?(children)

      raise ArgumentError, "key #{key} has already been defined" if
        children.key?(key)

      children[key] = Schema.new(**options, **kwargs, key:, type:, strict:, source:, casing:, parent: self, &block)
    end

    ##
    # params defines multiple like-parameters for a hash schema.
    def params(*keys, **kwargs, &block) = keys.each { param(_1, **kwargs, &block) }

    ##
    # item defines an indexed parameter for an array schema.
    def item(key = children&.size || 0, type:, **kwargs, &block)
      raise NotImplementedError, "cannot define item for non-array type (got #{self.type})" unless
        Types.array?(children)

      raise ArgumentError, "index #{key} has already been defined" if
        children[key].present? || endless?

      children << Schema.new(**options, **kwargs, key:, type:, strict:, source:, casing:, parent: self, &block)
    end

    ##
    # items defines a set of like-parameters for an array schema.
    def items(**kwargs, &)
      item(0, **kwargs, &)

      endless!
    end

    def path
      key = @key == ROOT ? nil : @key

      @path ||= Path.new(*parent&.path&.keys, *key)
    end

    def keys
      return [] if
        children.blank?

      case children
      when Array
        (0...children.size).to_a
      when Hash
        children.keys
      else
        []
      end
    end

    def root?              = key == ROOT
    def child?             = !root?
    def children?          = !children.blank?
    def strict?            = !!strict
    def lenient?           = !strict?
    def optional?          = !!@optional
    def required?          = !optional?
    def coerce?            = !!@coerce
    def polymorphic?       = !!@polymorphic
    def aliased?           = !!@alias
    def allow_blank?       = !!@allow_blank
    def allow_nil?         = !!@allow_nil
    def allow_non_scalars? = !!@allow_non_scalars
    def nilify_blanks?     = !!@nilify_blanks
    def endless?           = !!@endless
    def indexed?           = !endless?
    def if?                = !@if.nil?
    def unless?            = !@unless.nil?
    def array?             = Types.array?(type)
    def hash?              = Types.hash?(type)
    def scalar?            = Types.scalar?(type)
    def formatter?         = !!@formatter

    def inspect
      "#<#{self.class.name} key=#{key.inspect} type=#{type.inspect} children=#{children.inspect}>"
    end

    private

    attr_reader :controller,
                :options,
                :strict,
                :casing

    def endless! = @endless = true
  end
end
