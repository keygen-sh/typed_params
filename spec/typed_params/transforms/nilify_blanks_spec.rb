# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Transforms::NilifyBlanks do
  let(:transform) { TypedParams::Transforms::NilifyBlanks.new }

  context 'with blank string' do
    it 'should transform to nil' do
      schema = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, allow_nil: true }
      params = TypedParams::Parameterizer.new(schema:).call(value: { foo: '' })

      transform.call(params[:foo])

      expect(params[:foo].key).to eq :foo
      expect(params[:foo].value).to be nil
    end
  end

  context 'with present string' do
    it 'should not transform to nil' do
      schema = TypedParams::Schema.new(type: :hash) { param :foo, type: :string }
      params = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'bar' })

      transform.call(params[:foo])

      expect(params[:foo].key).to eq :foo
      expect(params[:foo].value).to eq 'bar'
    end
  end

  context 'with empty array' do
    it 'should not transform to nil' do
      schema = TypedParams::Schema.new(type: :hash) { param :foo, type: :array }
      params = TypedParams::Parameterizer.new(schema:).call(value: { foo: [] })

      transform.call(params[:foo])

      expect(params[:foo].value).to eq []
    end
  end

  context 'with empty hash' do
    it 'should not transform to nil' do
      schema = TypedParams::Schema.new(type: :hash) { param :foo, type: :hash }
      params = TypedParams::Parameterizer.new(schema:).call(value: { foo: {} })

      transform.call(params[:foo])

      expect(params[:foo].value).to eq({})
    end
  end
end
