# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Transforms::Transform do
  describe '.wrap' do
    it 'should wrap a Proc in Wrapped' do
      fn        = ->(key, value) { [key, value.upcase] }
      transform = TypedParams::Transforms::Transform.wrap(fn)

      expect(transform).to be_a TypedParams::Transforms::Wrapped
    end

    it 'should return a Transform as-is' do
      transform = TypedParams::Transforms::KeyAlias.new(:bar)
      wrapped   = TypedParams::Transforms::Transform.wrap(transform)

      expect(wrapped).to be transform
    end
  end

  describe TypedParams::Transforms::Wrapped do
    it 'should transform key and value' do
      fn        = ->(key, value) { [:"#{key}_transformed", value.upcase] }
      transform = TypedParams::Transforms::Wrapped.new(fn)
      schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string }
      params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'bar' })
      child     = params[:foo]

      transform.call(child)

      expect(child.key).to eq :foo_transformed
      expect(child.value).to eq 'BAR'
    end

    it 'should only transform value when key unchanged' do
      fn        = ->(key, value) { [key, value.upcase] }
      transform = TypedParams::Transforms::Wrapped.new(fn)
      schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string }
      params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'bar' })
      child     = params[:foo]

      transform.call(child)

      expect(child.key).to eq :foo
      expect(child.value).to eq 'BAR'
    end

    it 'should delete param when key is nil' do
      fn        = ->(_key, _value) { [nil, nil] }
      transform = TypedParams::Transforms::Wrapped.new(fn)
      schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string }
      params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'bar' })
      child     = params[:foo]

      transform.call(child)

      expect(child).to be_deleted
    end
  end

  describe 'custom Transform class' do
    let(:custom_transform_class) do
      Class.new(TypedParams::Transforms::Transform) do
        def call(param)
          param.value = param.value.reverse
        end
      end
    end

    it 'should accept a custom Transform instance' do
      transform = custom_transform_class.new
      schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, transform: }
      params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'bar' })

      TypedParams::Processor.new(schema:).call(params)

      expect(params[:foo].value).to eq 'rab'
    end
  end
end
