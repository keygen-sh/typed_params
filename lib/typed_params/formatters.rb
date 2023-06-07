# frozen_string_literal: true

require 'typed_params/formatters/formatter'

module TypedParams
  module Formatters
    cattr_reader :formats, default: {}

    def self.register(format, transform:, decorate: nil)
      raise ArgumentError, "format is already registered: #{format.inspect}" if
        formats.key?(format)

      formats[format] = Formatter.new(format, transform:, decorate:)
    end

    def self.unregister(type) = formats.delete(type)

    def self.[](format) = formats[format] || raise(ArgumentError, "invalid format: #{format.inspect}")
  end
end
