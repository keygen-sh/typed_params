# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Coercer do
  let :schema do
    TypedParameters::Schema.new type: :hash do
      param :boolean, type: :boolean, coerce: true
      param :string, type: :string, coerce: true
      param :integer, type: :integer, coerce: true
      param :float, type: :float, coerce: true
      param :decimal, type: :decimal, coerce: true
      param :date, type: :date, coerce: true
      param :time, type: :time, coerce: true
      param :nil, type: :nil, coerce: true
      param :hash, type: :hash, coerce: true
      param :array, type: :array, coerce: true
    end
  end

  it 'should coerce true' do
    params  = TypedParameters::Parameterizer.new(schema:).call(value: { boolean: 1 })
    coercer = TypedParameters::Coercer.new(schema:)

    coercer.call(params)

    expect(params[:boolean].value).to be true
  end

  it 'should coerce false' do
    params  = TypedParameters::Parameterizer.new(schema:).call(value: { boolean: 0 })
    coercer = TypedParameters::Coercer.new(schema:)

    coercer.call(params)

    expect(params[:boolean].value).to be false
  end

  it 'should coerce string' do
    params  = TypedParameters::Parameterizer.new(schema:).call(value: { string: 1 })
    coercer = TypedParameters::Coercer.new(schema:)

    coercer.call(params)

    expect(params[:string].value).to eq '1'
  end

  it 'should coerce integer' do
    params  = TypedParameters::Parameterizer.new(schema:).call(value: { integer: '1' })
    coercer = TypedParameters::Coercer.new(schema:)

    coercer.call(params)

    expect(params[:integer].value).to eq 1
  end

  it 'should coerce float' do
    params  = TypedParameters::Parameterizer.new(schema:).call(value: { float: 1 })
    coercer = TypedParameters::Coercer.new(schema:)

    coercer.call(params)

    expect(params[:float].value).to eq 1.0
  end

  it 'should coerce decimal' do
    params  = TypedParameters::Parameterizer.new(schema:).call(value: { decimal: 1 })
    coercer = TypedParameters::Coercer.new(schema:)

    coercer.call(params)

    expect(params[:decimal].value).to eq 1.0.to_d
  end

  it 'should coerce date' do
    now = Date.today

    params  = TypedParameters::Parameterizer.new(schema:).call(value: { date: now.to_s })
    coercer = TypedParameters::Coercer.new(schema:)

    coercer.call(params)

    expect(params[:date].value).to eq now
  end

  it 'should coerce time' do
    now = Time.now

    params  = TypedParameters::Parameterizer.new(schema:).call(value: { time: now.strftime('%H:%M:%S.%9N') })
    coercer = TypedParameters::Coercer.new(schema:)

    coercer.call(params)

    expect(params[:time].value).to eq now
  end

  it 'should coerce nil' do
    params  = TypedParameters::Parameterizer.new(schema:).call(value: { nil: 1 })
    coercer = TypedParameters::Coercer.new(schema:)

    coercer.call(params)

    expect(params[:nil].value).to be nil
  end

  it 'should coerce array' do
    params  = TypedParameters::Parameterizer.new(schema:).call(value: { array: '1,2,3' })
    coercer = TypedParameters::Coercer.new(schema:)

    coercer.call(params)

    expect(params[:array].value).to eq %w[1 2 3]
  end

  it 'should coerce hash' do
    params  = TypedParameters::Parameterizer.new(schema:).call(value: { hash: [[:foo, 1]] })
    coercer = TypedParameters::Coercer.new(schema:)

    coercer.call(params)

    expect(params[:hash].value).to eq({ foo: 1 })
  end
end