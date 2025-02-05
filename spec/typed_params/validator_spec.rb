# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Validator do
  let :schema do
    TypedParams::Schema.new type: :hash do
      param :foo, type: :hash do
        param :bar, type: :array do
          items type: :hash do
            param :baz, type: :integer
          end
        end
      end
    end
  end

  it 'should not raise on type match' do
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 0 }] } })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on type mismatch' do
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 'qux' }] } })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on missing optional root' do
    schema    = TypedParams::Schema.new(type: :hash, optional: true)
    params    = TypedParams::Parameterizer.new(schema:).call(value: nil)
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on missing required root' do
    schema    = TypedParams::Schema.new(type: :hash, optional: false)
    params    = TypedParams::Parameterizer.new(schema:).call(value: nil)
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on missing optional param' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, optional: true }
    params    = TypedParams::Parameterizer.new(schema:).call(value: {})
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on missing nested required params' do
    schema = TypedParams::Schema.new(type: :hash) do
      param :foo, type: :hash do
        param :bar, type: :hash do
          param :baz, type: :string
        end
      end
    end

    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: {} })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on missing nested optional params' do
    schema = TypedParams::Schema.new(type: :hash) do
      param :foo, type: :hash do
        param :bar, type: :hash, optional: true do
          param :baz, type: :string, optional: true
        end
      end
    end

    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: {} })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on missing nested nilable params' do
    schema = TypedParams::Schema.new(type: :hash) do
      param :foo, type: :hash do
        param :bar, type: :hash, allow_nil: true do
          param :baz, type: :string
        end
      end
    end

    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: {} })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should raise on missing required param' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, optional: false }
    params    = TypedParams::Parameterizer.new(schema:).call(value: {})
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on nil param' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: true }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: nil })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should skip :validate validation on nil param' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: true, validate: -> v { v == 1 } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: nil })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on nil param' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: nil })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on false param' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :boolean, allow_blank: false }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: false })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should not raise on 0 param' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, allow_blank: false }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 0 })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should not raise on 0.0 param' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :float, allow_blank: false }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 0.0 })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should not raise on blank param' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, allow_blank: true }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: '' })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should skip :length validation on blank param' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, allow_blank: true, length: { is: 3 } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: '' })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on blank param' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, allow_blank: false }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: '' })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on :inclusion param validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, inclusion: { in: %w[a b c] } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'b' })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on :inclusion param validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, inclusion: { in: %w[a b c] } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'd' })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on :exclusion param validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, exclusion: { in: %w[a b c] } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'd' })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on :exclusion param validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, exclusion: { in: %w[a b c] } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'c' })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on param :with format validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, format: { with: /bar/ } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'bar' })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :with format validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, format: { with: /bar/ } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'baz' })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on param :without format validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, format: { without: /^a/ } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'z' })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :without format validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, format: { without: /^a/ } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'a' })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on param :minimum length validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :array, length: { minimum: 3 } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: %w[a b c] })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :minimum length validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :array, length: { minimum: 3 } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: %w[a b] })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on param :maximum length validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :array, length: { maximum: 3 } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: %w[a b c] })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :maximum length validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :array, length: { maximum: 3 } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: %w[a b c d] })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on param :within length validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :array, length: { within: 1..3 } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: %w[a b c] })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :within length validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :array, length: { within: 1..3 } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: %w[] })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on param :in length validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :array, length: { in: 1..3 } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: %w[a b c] })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :in length validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :array, length: { in: 1..3 } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: %w[a b c d] })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on param :is length validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :array, length: { is: 2 } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: %w[a b] })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :is length validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :array, length: { is: 2 } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: %w[a] })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on param :validate validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, validate: -> v { v == 'ok' } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'ok' })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :validate validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, validate: -> v { v == 'ok' } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'ko' })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should raise on mutually exclusive :validate validation' do
    schema = TypedParams::Schema.new(type: :hash, validate: -> v { v.key?(:foo) ^ v.key?(:bar) }) do
      param :foo, type: :integer, optional: true
      param :bar, type: :integer, optional: true
      param :baz, type: :integer
    end

    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 1, bar: 2, baz: 3 })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on mutually exclusive :validate validation' do
    schema = TypedParams::Schema.new(type: :hash, validate: -> v { v.key?(:foo) ^ v.key?(:bar) }) do
      param :foo, type: :integer, optional: true
      param :bar, type: :integer, optional: true
      param :baz, type: :integer
    end

    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 1, baz: 3 })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise with a custom error message for :validate validation' do
    schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, validate: -> v { raise TypedParams::ValidationError, 'foo' } }
    params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'bar' })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error { |err|
      expect(err).to be_a TypedParams::InvalidParameterError
      expect(err.message).to eq 'foo'
    }
  end

  it 'should not raise on hash of scalar values' do
    schema    = TypedParams::Schema.new(type: :hash)
    params    = TypedParams::Parameterizer.new(schema:).call(value: { a: 1, b: 2, c: 3 })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on hash of non-scalar values' do
    schema    = TypedParams::Schema.new(type: :hash)
    params    = TypedParams::Parameterizer.new(schema:).call(value: { a: 1, b: 2, c: { d: 3 } })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on hash of non-scalar values' do
    schema    = TypedParams::Schema.new(type: :hash, allow_non_scalars: true)
    params    = TypedParams::Parameterizer.new(schema:).call(value: { a: 1, b: 2, c: { d: 3 } })
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should not raise on array of scalar values' do
    schema    = TypedParams::Schema.new(type: :array)
    params    = TypedParams::Parameterizer.new(schema:).call(value: [1, 2, 3])
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should not raise on empty array' do
    schema    = TypedParams::Schema.new(type: :array)
    params    = TypedParams::Parameterizer.new(schema:).call(value: [])
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on array of non-scalar values' do
    schema    = TypedParams::Schema.new(type: :array)
    params    = TypedParams::Parameterizer.new(schema:).call(value: [1, 2, [3]])
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
  end

  it 'should not raise on array of non-scalar values' do
    schema    = TypedParams::Schema.new(type: :array, allow_non_scalars: true)
    params    = TypedParams::Parameterizer.new(schema:).call(value: [1, 2, [3]])
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should not raise on array of objects' do
    schema = TypedParams::Schema.new type: :array do
      items type: :hash do
        param :key, type: :string
      end
    end

    params    = TypedParams::Parameterizer.new(schema:).call(value: [key: 'value'])
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should not raise on empty array of objects' do
    schema = TypedParams::Schema.new type: :array do
      items type: :hash do
        param :key, type: :string
      end
    end

    params    = TypedParams::Parameterizer.new(schema:).call(value: [])
    validator = TypedParams::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  context 'with config to not ignore optional nils' do
    before do
      @ignore_nil_optionals_was = TypedParams.config.ignore_nil_optionals

      TypedParams.config.ignore_nil_optionals = false
    end

    after do
      TypedParams.config.ignore_nil_optionals = @ignore_nil_optionals_was
    end

    it 'should raise on required nil param' do
      schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false, optional: false }
      params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: nil })
      validator = TypedParams::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
    end

    it 'should raise on optional nil param' do
      schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false, optional: true }
      params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: nil })
      validator = TypedParams::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
    end
  end

  context 'with config to ignore optional nils' do
    before do
      @ignore_nil_optionals_was = TypedParams.config.ignore_nil_optionals

      TypedParams.config.ignore_nil_optionals = true
    end

    after do
      TypedParams.config.ignore_nil_optionals = @ignore_nil_optionals_was
    end

    it 'should raise on required nil param' do
      schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false, optional: false }
      params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: nil })
      validator = TypedParams::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
    end

    it 'should not raise on optional nil param' do
      schema    = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false, optional: true }
      params    = TypedParams::Parameterizer.new(schema:).call(value: { foo: nil })
      validator = TypedParams::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end
  end

  context 'with :params source' do
    let(:schema) { TypedParams::Schema.new(type: :hash, source: :params) }

    it 'should have a correct source' do
      params    = TypedParams::Parameterizer.new(schema:).call(value: [])
      validator = TypedParams::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error { |err|
        expect(err).to be_a TypedParams::InvalidParameterError
        expect(err.source).to eq :params
      }
    end
  end

  context 'with :query source' do
    let(:schema) { TypedParams::Schema.new(type: :hash, source: :query) }

    it 'should have a correct source' do
      params    = TypedParams::Parameterizer.new(schema:).call(value: [])
      validator = TypedParams::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error { |err|
        expect(err).to be_a TypedParams::InvalidParameterError
        expect(err.source).to eq :query
      }
    end
  end

  context 'with nil source' do
    let(:schema) { TypedParams::Schema.new(type: :hash) }

    it 'should have a correct source' do
      params    = TypedParams::Parameterizer.new(schema:).call(value: [])
      validator = TypedParams::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error { |err|
        expect(err).to be_a TypedParams::InvalidParameterError
        expect(err.source).to be nil
      }
    end
  end

  context 'with subtype' do
    let(:schema) { TypedParams::Schema.new(type: :hash) { param :metadata, type: :shallow_hash } }

    before do
      TypedParams::Types.register(:shallow_hash,
        archetype: :hash,
        match: -> v {
          v.is_a?(Hash) && v.values.none? { _1.is_a?(Array) || _1.is_a?(Hash) }
        },
      )
    end

    after do
      TypedParams::Types.unregister(:shallow_hash)
    end

    it 'should not raise' do
      params    = TypedParams::Parameterizer.new(schema:).call(value: { metadata: { foo: 'bar', baz: 'qux' }})
      validator = TypedParams::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise' do
      params    = TypedParams::Parameterizer.new(schema:).call(value: { metadata: { foo: { bar: 'baz' } } })
      validator = TypedParams::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParams::InvalidParameterError
    end
  end
end
