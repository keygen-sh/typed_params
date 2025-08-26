# frozen_string_literal: true

module TypedParams
  class Path
    attr_reader :keys

    def initialize(*keys, casing: TypedParams.config.path_transform)
      @casing = casing
      @keys   = keys
    end

    def to_json_pointer = '/' + keys.map { transform_key(_1) }.join('/')
    def to_dot_notation = keys.map { transform_key(_1) }.join('.')

    def +(other)
      raise ArgumentError, 'must be a Path object or nil' unless other in Path | nil

      return self if
        other.nil?

      Path.new(*keys, *other.keys, casing:)
    end

    def to_s
      keys.map { transform_key(_1) }.reduce(+'') do |s, key|
        case key
        when Integer
          s << "[#{key}]"
        else
          s << '.' unless s.blank?
          s << key.to_s
        end
      end
    end

    def inspect
      "#<#{self.class.name}: #{to_s.inspect} keys=#{keys.inspect} casing=#{casing.inspect}>"
    end

    private

    attr_reader :casing

    def transform_string(str)
      case casing
      when :underscore
        str.underscore
      when :camel
        str.underscore.camelize
      when :lower_camel
        str.underscore.camelize(:lower)
      when :dash
        str.underscore.dasherize
      else
        str
      end
    end

    def transform_key(key)
      return key if key.is_a?(Integer)

      transform_string(key.to_s)
    end
  end
end
