# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Parameterizer do
  it 'should parameterize array' do
    schema = TypedParameters::Schema.new(type: :array) { items(type: :hash) { param(:key, type: :symbol) } }
    paramz = TypedParameters::Parameterizer.new(schema:)
    params = [{ key: :foo }, { key: :bar }, { key: :baz }]

    expect(paramz.call(value: params)).to satisfy { |res|
      res in TypedParameters::Parameter(
        value: [
          TypedParameters::Parameter(
            value: {
              key: TypedParameters::Parameter(value: :foo),
            },
          ),
          TypedParameters::Parameter(
            value: {
              key: TypedParameters::Parameter(value: :bar),
            },
          ),
          TypedParameters::Parameter(
            value: {
              key: TypedParameters::Parameter(value: :baz),
            },
          ),
        ],
      )
    }
  end

  it 'should parameterize hash' do
    schema = TypedParameters::Schema.new(type: :hash) { param(:foo, type: :hash) { param(:bar, type: :symbol) } }
    paramz = TypedParameters::Parameterizer.new(schema:)
    params = { foo: { bar: :baz } }

    expect(paramz.call(value: params)).to satisfy { |res|
      res in TypedParameters::Parameter(
        value: {
          foo: TypedParameters::Parameter(
            value: {
              bar: TypedParameters::Parameter(value: :baz),
            },
          ),
        },
      )
    }
  end

  it 'should parameterize scalar' do
    schema = TypedParameters::Schema.new(type: :symbol)
    paramz = TypedParameters::Parameterizer.new(schema:)
    params = :foo

    expect(paramz.call(value: params)).to satisfy { |res|
      res in TypedParameters::Parameter(value: :foo)
    }
  end

  it 'should not parameterize nil' do
    schema = TypedParameters::Schema.new(type: :hash)
    paramz = TypedParameters::Parameterizer.new(schema:)
    params = nil

    expect(paramz.call(value: params)).to be nil
  end

  it 'should not raise on unbounded array' do
    schema = TypedParameters::Schema.new(type: :array) { items type: :string }
    paramz = TypedParameters::Parameterizer.new(schema:)
    params = %w[
      foo
      bar
      baz
    ]

    expect { paramz.call(value: params) }.to_not raise_error
  end

  it 'should not raise on bounded array' do
    schema = TypedParameters::Schema.new(type: :array) { item type: :string; item type: :string }
    paramz = TypedParameters::Parameterizer.new(schema:)
    params = %w[
      foo
      bar
    ]

    expect { paramz.call(value: params) }.to_not raise_error
  end

  it 'should raise on bounded array' do
    schema = TypedParameters::Schema.new(type: :array) { item type: :string; item type: :string }
    paramz = TypedParameters::Parameterizer.new(schema:)
    params = %w[
      foo
      bar
      baz
    ]

    expect { paramz.call(value: params) }.to raise_error TypedParameters::UnpermittedParameterError
  end

  it 'should raise when schema has no children' do
    schema = TypedParameters::Schema.new(type: :hash) {}
    paramz = TypedParameters::Parameterizer.new(schema:)
    params = { foo: 1 }

    expect { paramz.call(value: params) }.to raise_error TypedParameters::UnpermittedParameterError
  end

  context 'with non-strict schema' do
    let(:schema) { TypedParameters::Schema.new(strict: false) { param :foo, type: :string } }

    it 'should not raise on unpermitted params' do
      paramz = TypedParameters::Parameterizer.new(schema:)
      params = { bar: 'baz' }

      expect { paramz.call(value: params) }.to_not raise_error
    end

    it 'should delete unpermitted params' do
      paramz = TypedParameters::Parameterizer.new(schema:)
      params = { bar: 'baz' }

      expect(paramz.call(value: params)).to_not have_key :bar
    end
  end

  context 'with strict schema' do
    let(:schema) { TypedParameters::Schema.new(strict: true) { param :foo, type: :string } }

    it 'should raise on unpermitted params' do
      paramz = TypedParameters::Parameterizer.new(schema:)
      params = { bar: 'baz' }

      expect { paramz.call(value: params) }.to raise_error TypedParameters::UnpermittedParameterError
    end
  end
end