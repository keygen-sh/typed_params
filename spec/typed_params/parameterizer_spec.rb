# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Parameterizer do
  it 'should parameterize array' do
    schema = TypedParams::Schema.new(type: :array) { items(type: :hash) { param(:key, type: :symbol) } }
    paramz = TypedParams::Parameterizer.new(schema:)
    params = [{ key: :foo }, { key: :bar }, { key: :baz }]

    expect(paramz.call(value: params)).to satisfy { |res|
      res in TypedParams::Parameter(
        value: [
          TypedParams::Parameter(
            value: {
              key: TypedParams::Parameter(value: :foo),
            },
          ),
          TypedParams::Parameter(
            value: {
              key: TypedParams::Parameter(value: :bar),
            },
          ),
          TypedParams::Parameter(
            value: {
              key: TypedParams::Parameter(value: :baz),
            },
          ),
        ],
      )
    }
  end

  it 'should parameterize array with nil child' do
    schema = TypedParams::Schema.new(type: :array) { items(type: :hash) { param(:key, type: :symbol) } }
    paramz = TypedParams::Parameterizer.new(schema:)
    params = [nil]

    expect(paramz.call(value: params)).to satisfy { |res|
      res in TypedParams::Parameter(
        value: [
          TypedParams::Parameter(
            value: nil,
          ),
        ],
      )
    }
  end

  it 'should parameterize hash' do
    schema = TypedParams::Schema.new(type: :hash) { param(:foo, type: :hash) { param(:bar, type: :symbol) } }
    paramz = TypedParams::Parameterizer.new(schema:)
    params = { foo: { bar: :baz } }

    expect(paramz.call(value: params)).to satisfy { |res|
      res in TypedParams::Parameter(
        value: {
          foo: TypedParams::Parameter(
            value: {
              bar: TypedParams::Parameter(value: :baz),
            },
          ),
        },
      )
    }
  end

  it 'should parameterize hash with nil child' do
    schema = TypedParams::Schema.new(type: :hash) { param(:foo, type: :hash) { param(:bar, type: :symbol) } }
    paramz = TypedParams::Parameterizer.new(schema:)
    params = { foo: nil }

    expect(paramz.call(value: params)).to satisfy { |res|
      res in TypedParams::Parameter(
        value: {
          foo: TypedParams::Parameter(
            value: nil,
          ),
        },
      )
    }
  end

  it 'should parameterize scalar' do
    schema = TypedParams::Schema.new(type: :symbol)
    paramz = TypedParams::Parameterizer.new(schema:)
    params = :foo

    expect(paramz.call(value: params)).to satisfy { |res|
      res in TypedParams::Parameter(value: :foo)
    }
  end

  it 'should not parameterize nil' do
    schema = TypedParams::Schema.new(type: :hash)
    paramz = TypedParams::Parameterizer.new(schema:)
    params = nil

    expect(paramz.call(value: params)).to be nil
  end

  it 'should not raise on unbounded array' do
    schema = TypedParams::Schema.new(type: :array) { items type: :string }
    paramz = TypedParams::Parameterizer.new(schema:)
    params = %w[
      foo
      bar
      baz
    ]

    expect { paramz.call(value: params) }.to_not raise_error
  end

  it 'should not raise on bounded array' do
    schema = TypedParams::Schema.new(type: :array) { item type: :string; item type: :string }
    paramz = TypedParams::Parameterizer.new(schema:)
    params = %w[
      foo
      bar
    ]

    expect { paramz.call(value: params) }.to_not raise_error
  end

  it 'should raise on bounded array' do
    schema = TypedParams::Schema.new(type: :array) { item type: :string; item type: :string }
    paramz = TypedParams::Parameterizer.new(schema:)
    params = %w[
      foo
      bar
      baz
    ]

    expect { paramz.call(value: params) }.to raise_error TypedParams::UnpermittedParameterError
  end

  it 'should raise when schema has no children' do
    schema = TypedParams::Schema.new(type: :hash) {}
    paramz = TypedParams::Parameterizer.new(schema:)
    params = { foo: 1 }

    expect { paramz.call(value: params) }.to raise_error TypedParams::UnpermittedParameterError
  end

  context 'with non-strict schema' do
    let(:schema) { TypedParams::Schema.new(strict: false) { param :foo, type: :string } }

    it 'should not raise on unpermitted params' do
      paramz = TypedParams::Parameterizer.new(schema:)
      params = { bar: 'baz' }

      expect { paramz.call(value: params) }.to_not raise_error
    end

    it 'should delete unpermitted params' do
      paramz = TypedParams::Parameterizer.new(schema:)
      params = { bar: 'baz' }

      expect(paramz.call(value: params)).to_not have_key :bar
    end
  end

  context 'with strict schema' do
    let(:schema) { TypedParams::Schema.new(strict: true) { param :foo, type: :string } }

    it 'should raise on unpermitted params' do
      paramz = TypedParams::Parameterizer.new(schema:)
      params = { bar: 'baz' }

      expect { paramz.call(value: params) }.to raise_error TypedParams::UnpermittedParameterError
    end
  end
end