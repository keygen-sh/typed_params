# frozen_string_literal: true

require 'typed_params/bouncer'
require 'typed_params/coercer'
require 'typed_params/configuration'
require 'typed_params/controller'
require 'typed_params/formatters'
require 'typed_params/formatters/formatter'
require 'typed_params/formatters/jsonapi'
require 'typed_params/formatters/rails'
require 'typed_params/handler_set'
require 'typed_params/handler'
require 'typed_params/mapper'
require 'typed_params/namespaced_set'
require 'typed_params/parameter'
require 'typed_params/parameterizer'
require 'typed_params/path'
require 'typed_params/pipeline'
require 'typed_params/processor'
require 'typed_params/schema_set'
require 'typed_params/schema'
require 'typed_params/transforms/key_alias'
require 'typed_params/transforms/key_casing'
require 'typed_params/transforms/nilify_blanks'
require 'typed_params/transforms/noop'
require 'typed_params/transforms/transform'
require 'typed_params/transformer'
require 'typed_params/types'
require 'typed_params/types/any'
require 'typed_params/types/array'
require 'typed_params/types/boolean'
require 'typed_params/types/date'
require 'typed_params/types/decimal'
require 'typed_params/types/float'
require 'typed_params/types/hash'
require 'typed_params/types/integer'
require 'typed_params/types/nil'
require 'typed_params/types/number'
require 'typed_params/types/string'
require 'typed_params/types/symbol'
require 'typed_params/types/time'
require 'typed_params/types/type'
require 'typed_params/validations/exclusion'
require 'typed_params/validations/format'
require 'typed_params/validations/inclusion'
require 'typed_params/validations/length'
require 'typed_params/validations/validation'
require 'typed_params/validator'

module TypedParams
  # Sentinel value for determining if something should be automatic.
  # For example, automatically detecting a param's format via its
  # schema vs using an explicitly provided format.
  AUTO = Object.new

  # Sentinel value for determining if something is the root. For
  # example, determining if a schema is the root node.
  ROOT = Object.new

  class UndefinedActionError < StandardError; end
  class InvalidMethodError < StandardError; end
  class ValidationError < StandardError; end
  class CoercionError < StandardError; end

  class InvalidParameterError < StandardError
    attr_reader :source,
                :path

    def initialize(message, source:, path:)
      @source = source
      @path   = path

      super(message)
    end

    def inspect
      "#<#{self.class.name} message=#{message.inspect} source=#{source.inspect} path=#{path.inspect}>"
    end
  end

  class UnpermittedParameterError < InvalidParameterError; end

  def self.formats = Formatters
  def self.types   = Types

  def self.config = @config ||= Configuration.new
  def self.configure
    yield config
  end
end
