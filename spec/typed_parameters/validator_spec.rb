# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Validator do
  let :schema do
    TypedParameters::Schema.new type: :hash do
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
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 0 }] } })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on type mismatch' do
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 'qux' }] } })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on missing optional root' do
    schema    = TypedParameters::Schema.new(type: :hash, optional: true)
    params    = TypedParameters::Parameterizer.new(schema:).call(value: nil)
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on missing required root' do
    schema    = TypedParameters::Schema.new(type: :hash, optional: false)
    params    = TypedParameters::Parameterizer.new(schema:).call(value: nil)
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on missing optional param' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, optional: true }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: {})
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should not raise on missing nested optional params' do
    schema = TypedParameters::Schema.new(type: :hash) do
      param :foo, type: :hash do
        param :bar, type: :hash, optional: true do
          param :baz, type: :string, optional: true
        end
      end
    end

    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: {} })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on missing required param' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, optional: false }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: {})
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on nil param' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: true }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: nil })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should skip :validate validation on nil param' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: true, validate: -> v { v == 1 } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: nil })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on nil param' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: nil })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on false param' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :boolean, allow_blank: false }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: false })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should not raise on 0 param' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, allow_blank: false }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 0 })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should not raise on 0.0 param' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :float, allow_blank: false }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 0.0 })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should not raise on blank param' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, allow_blank: true }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: '' })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should skip :length validation on blank param' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, allow_blank: true, length: { is: 3 } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: '' })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on blank param' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, allow_blank: false }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: '' })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on :inclusion param validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, inclusion: { in: %w[a b c] } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'b' })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on :inclusion param validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, inclusion: { in: %w[a b c] } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'd' })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on :exclusion param validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, exclusion: { in: %w[a b c] } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'd' })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on :exclusion param validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, exclusion: { in: %w[a b c] } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'c' })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on param :with format validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, format: { with: /bar/ } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'bar' })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :with format validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, format: { with: /bar/ } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'baz' })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on param :without format validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, format: { without: /^a/ } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'z' })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :without format validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, format: { without: /^a/ } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'a' })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on param :minimum length validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { minimum: 3 } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b c] })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :minimum length validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { minimum: 3 } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b] })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on param :maximum length validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { maximum: 3 } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b c] })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :maximum length validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { maximum: 3 } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b c d] })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on param :within length validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { within: 1..3 } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b c] })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :within length validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { within: 1..3 } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[] })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on param :in length validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { in: 1..3 } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b c] })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :in length validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { in: 1..3 } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b c d] })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on param :is length validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { is: 2 } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b] })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :is length validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { is: 2 } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a] })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on param :validate validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, validate: -> v { v == 'ok' } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'ok' })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on param :validate validation' do
    schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, validate: -> v { v == 'ok' } }
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'ko' })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on hash of scalar values' do
    schema    = TypedParameters::Schema.new(type: :hash)
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { a: 1, b: 2, c: 3 })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on hash of non-scalar values' do
    schema    = TypedParameters::Schema.new(type: :hash)
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { a: 1, b: 2, c: { d: 3 } })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on hash of non-scalar values' do
    schema    = TypedParameters::Schema.new(type: :hash, allow_non_scalars: true)
    params    = TypedParameters::Parameterizer.new(schema:).call(value: { a: 1, b: 2, c: { d: 3 } })
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should not raise on array of scalar values' do
    schema    = TypedParameters::Schema.new(type: :array)
    params    = TypedParameters::Parameterizer.new(schema:).call(value: [1, 2, 3])
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  it 'should raise on array of non-scalar values' do
    schema    = TypedParameters::Schema.new(type: :array)
    params    = TypedParameters::Parameterizer.new(schema:).call(value: [1, 2, [3]])
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
  end

  it 'should not raise on array of non-scalar values' do
    schema    = TypedParameters::Schema.new(type: :array, allow_non_scalars: true)
    params    = TypedParameters::Parameterizer.new(schema:).call(value: [1, 2, [3]])
    validator = TypedParameters::Validator.new(schema:)

    expect { validator.call(params) }.to_not raise_error
  end

  context 'with config to not ignore optional nils' do
    before do
      @ignore_nil_optionals_was = TypedParameters.config.ignore_nil_optionals

      TypedParameters.config.ignore_nil_optionals = false
    end

    after do
      TypedParameters.config.ignore_nil_optionals = @ignore_nil_optionals_was
    end

    it 'should raise on required nil param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false, optional: false }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: nil })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should raise on optional nil param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false, optional: true }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: nil })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end
  end

  context 'with config to ignore optional nils' do
    before do
      @ignore_nil_optionals_was = TypedParameters.config.ignore_nil_optionals

      TypedParameters.config.ignore_nil_optionals = true
    end

    after do
      TypedParameters.config.ignore_nil_optionals = @ignore_nil_optionals_was
    end

    it 'should raise on required nil param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false, optional: false }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: nil })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on optional nil param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false, optional: true }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: nil })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end
  end

  context 'with :params source' do
    let(:schema) { TypedParameters::Schema.new(type: :hash, source: :params) }

    it 'should have a correct source' do
      params    = TypedParameters::Parameterizer.new(schema:).call(value: [])
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error { |err|
        expect(err).to be_a TypedParameters::InvalidParameterError
        expect(err.source).to eq :params
      }
    end
  end

  context 'with :query source' do
    let(:schema) { TypedParameters::Schema.new(type: :hash, source: :query) }

    it 'should have a correct source' do
      params    = TypedParameters::Parameterizer.new(schema:).call(value: [])
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error { |err|
        expect(err).to be_a TypedParameters::InvalidParameterError
        expect(err.source).to eq :query
      }
    end
  end

  context 'with nil source' do
    let(:schema) { TypedParameters::Schema.new(type: :hash) }

    it 'should have a correct source' do
      params    = TypedParameters::Parameterizer.new(schema:).call(value: [])
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error { |err|
        expect(err).to be_a TypedParameters::InvalidParameterError
        expect(err.source).to be nil
      }
    end
  end

  context 'with subtype' do
    let(:schema) { TypedParameters::Schema.new(type: :hash) { param :metadata, type: :shallow_hash } }

    before do
      TypedParameters::Types.register(:shallow_hash,
        archetype: :hash,
        match: -> v {
          v.is_a?(Hash) && v.values.none? { _1.is_a?(Array) || _1.is_a?(Hash) }
        },
      )
    end

    after do
      TypedParameters::Types.unregister(:shallow_hash)
    end

    it 'should not raise' do
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { metadata: { foo: 'bar', baz: 'qux' }})
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise' do
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { metadata: { foo: { bar: 'baz' } } })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end
  end
end