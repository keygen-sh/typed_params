# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Validations::Validation do
  describe '.wrap' do
    it 'should wrap a Proc in Wrapped' do
      fn         = ->(value) { value.present? }
      validation = TypedParams::Validations::Validation.wrap(fn)

      expect(validation).to be_a TypedParams::Validations::Wrapped
    end

    it 'should return a Validation as-is' do
      validation = TypedParams::Validations::Inclusion.new(in: [1, 2, 3])
      wrapped    = TypedParams::Validations::Validation.wrap(validation)

      expect(wrapped).to be validation
    end
  end

  describe TypedParams::Validations::Wrapped do
    it 'should pass when Proc returns true' do
      fn         = ->(value) { value.start_with?('foo') }
      validation = TypedParams::Validations::Wrapped.new(fn)

      expect { validation.call('foobar') }.to_not raise_error
    end

    it 'should fail when Proc returns false' do
      fn         = ->(value) { value.start_with?('foo') }
      validation = TypedParams::Validations::Wrapped.new(fn)

      expect { validation.call('barfoo') }.to raise_error TypedParams::ValidationError
    end
  end

  describe 'custom Validation class' do
    let(:custom_validation_class) do
      Class.new(TypedParams::Validations::Validation) do
        def call(value)
          raise TypedParams::ValidationError, 'must be palindrome' unless value == value.reverse
        end
      end
    end

    it 'should accept a custom Validation instance' do
      validation = custom_validation_class.new(nil)
      schema     = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, validate: validation }
      params     = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'racecar' })

      expect { TypedParams::Processor.new(schema:).call(params) }.to_not raise_error
    end

    it 'should raise for invalid value' do
      validation = custom_validation_class.new(nil)
      schema     = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, validate: validation }
      params     = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'bar' })

      expect { TypedParams::Processor.new(schema:).call(params) }.to raise_error TypedParams::InvalidParameterError, /must be palindrome/
    end
  end
end
