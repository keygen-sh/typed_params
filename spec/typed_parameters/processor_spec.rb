# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Processor do
  it 'should coerce, validate and transform params and not raise' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :bin, type: :string, coerce: true, format: { with: /\A\d+\z/ }, transform: -> k, v { [k, v.to_i.to_s(2)] } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { bin: 42 })
    processor = TypedParameters::Processor.new(schema:)

    processor.call(params)

    expect(params[:bin].value).to eq '101010'
  end

  it 'should coerce, validate and transform params and raise' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :bin, type: :string, coerce: true, format: { with: /\A\d+\z/ }, transform: -> k, v { [k, v.to_i.to_s(2)] } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { bin: 'foo' })
    processor = TypedParameters::Processor.new(schema:)

    expect { processor.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on param :if condition' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, if: -> { true } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'bar' })
    processor = TypedParameters::Processor.new(schema:)

    expect { processor.call(params) }.to_not raise_error
  end

  it 'should raise on param :if condition' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, if: -> { false } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'bar' })
    processor = TypedParameters::Processor.new(schema:)

    expect { processor.call(params) }.to raise_error TypedParameters::UnpermittedParameterError
  end

  it 'should not raise on param :unless condition' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, unless: -> { false } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'bar' })
    processor = TypedParameters::Processor.new(schema:)

    expect { processor.call(params) }.to_not raise_error
  end

  it 'should raise on param :unless condition' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, unless: -> { true } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'bar' })
    processor = TypedParameters::Processor.new(schema:)

    expect { processor.call(params) }.to raise_error TypedParameters::UnpermittedParameterError
  end

  it 'should include optional coercible nillable param when blank' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, coerce: true, allow_nil: true, optional: true }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: '' })
    processor = TypedParameters::Processor.new(schema:)

    processor.call(params)

    expect(params[:foo]).to_not be nil
    expect(params[:foo].key).to eq :foo
    expect(params[:foo].value).to be nil
  end

  it 'should not include optional coercible nillable param when omitted' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, coerce: true, allow_nil: true, optional: true }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: {})
    processor = TypedParameters::Processor.new(schema:)

    processor.call(params)

    expect(params[:foo]).to be nil
  end

  it 'should raise on optional coercible param when blank' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, coerce: true, optional: true }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: '' })
    processor = TypedParameters::Processor.new(schema:)

    expect { processor.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should raise on renamed param with guard' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, if: -> { false }, as: :bar }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1 })
    processor = TypedParameters::Processor.new(schema:)

    expect { processor.call(params) }.to raise_error { |err|
      expect(err).to be_a TypedParameters::UnpermittedParameterError
      expect(err.path.to_json_pointer).to eq '/foo'
    }
  end

  it 'should rename param' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, as: :bar }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1 })
    processor = TypedParameters::Processor.new(schema:)

    processor.call(params)

    expect(params[:foo]).to be nil
    expect(params[:bar]).to_not be nil
  end

  it 'should rename param with transform' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, as: :bar, transform: -> k, v { [k, v] } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1 })
    processor = TypedParameters::Processor.new(schema:)

    processor.call(params)

    expect(params[:foo]).to be nil
    expect(params[:bar]).to_not be nil
  end

  it 'should not rename param with reverse transform' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, as: :bar, transform: -> k, v { [:foo, v] } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1 })
    processor = TypedParameters::Processor.new(schema:)

    processor.call(params)

    expect(params[:foo]).to_not be nil
    expect(params[:bar]).to be nil
  end
end