# frozen_string_literal: true

require 'typed_parameters/bouncer'
require 'typed_parameters/coercer'
require 'typed_parameters/configuration'
require 'typed_parameters/controller'
require 'typed_parameters/formatters'
require 'typed_parameters/formatters/formatter'
require 'typed_parameters/formatters/jsonapi'
require 'typed_parameters/formatters/rails'
require 'typed_parameters/handler_set'
require 'typed_parameters/handler'
require 'typed_parameters/mapper'
require 'typed_parameters/namespaced_set'
require 'typed_parameters/parameter'
require 'typed_parameters/parameterizer'
require 'typed_parameters/path'
require 'typed_parameters/pipeline'
require 'typed_parameters/processor'
require 'typed_parameters/schema_set'
require 'typed_parameters/schema'
require 'typed_parameters/transforms/key_alias'
require 'typed_parameters/transforms/key_casing'
require 'typed_parameters/transforms/nilify_blanks'
require 'typed_parameters/transforms/noop'
require 'typed_parameters/transforms/transform'
require 'typed_parameters/transformer'
require 'typed_parameters/types'
require 'typed_parameters/types/array'
require 'typed_parameters/types/boolean'
require 'typed_parameters/types/date'
require 'typed_parameters/types/decimal'
require 'typed_parameters/types/float'
require 'typed_parameters/types/hash'
require 'typed_parameters/types/integer'
require 'typed_parameters/types/nil'
require 'typed_parameters/types/number'
require 'typed_parameters/types/string'
require 'typed_parameters/types/symbol'
require 'typed_parameters/types/time'
require 'typed_parameters/types/type'
require 'typed_parameters/validations/exclusion'
require 'typed_parameters/validations/format'
require 'typed_parameters/validations/inclusion'
require 'typed_parameters/validations/length'
require 'typed_parameters/validations/validation'
require 'typed_parameters/validator'

module TypedParameters
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
