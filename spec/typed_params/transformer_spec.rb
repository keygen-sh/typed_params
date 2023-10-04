# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Transformer do
  it 'should traverse params depth-first' do
    schema = TypedParams::Schema.new(type: :hash) do
      param :parent, type: :hash, transform: -> k, v { [:a, v[:b].to_i] } do
        param :child, type: :hash, transform: -> k, v { [:b, v[:c].to_i] } do
          param :grandchild, type: :hash, transform: -> k, v { [:c, v[:d].to_i] } do
            param :value, type: :integer, transform: -> k, v { [:d, v.to_i]}
          end
        end
      end
    end

    data        = { parent: { child: { grandchild: { value: 42 } } } }
    params      = TypedParams::Parameterizer.new(schema:).call(value: data)
    transformer = TypedParams::Transformer.new(schema:)

    transformer.call(params)

    expect(params[:a].value).to eq 42
  end

  it 'should not transform the param when omitted' do
    schema      = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer }
    params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: 1 })
    transformer = TypedParams::Transformer.new(schema:)

    transformer.call(params)

    expect(params[:foo].key).to eq :foo
    expect(params[:foo].value).to eq 1
  end

  it 'should not transform the param with noop' do
    schema      = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, transform: -> k, v { [k, v] } }
    params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: 1 })
    transformer = TypedParams::Transformer.new(schema:)

    transformer.call(params)

    expect(params[:foo].key).to eq :foo
    expect(params[:foo].value).to eq 1
  end

  it 'should transform array params' do
    schema      = TypedParams::Schema.new(type: :array) { item type: :integer, transform: -> k, v { [1, v + 1] } }
    params      = TypedParams::Parameterizer.new(schema:).call(value: [1] )
    transformer = TypedParams::Transformer.new(schema:)

    transformer.call(params)

    expect(params[0]).to be nil
    expect(params[1].key).to eq 1
    expect(params[1].value).to eq 2
  end

  it 'should transform hash params' do
    schema      = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, transform: -> k, v { [:bar, v + 1] } }
    params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: 1 })
    transformer = TypedParams::Transformer.new(schema:)

    transformer.call(params)

    expect(params[:bar].key).to eq :bar
    expect(params[:bar].value).to eq 2
  end

  it 'should not delete root param with no key or value' do
    schema      = TypedParams::Schema.new(type: :hash, transform: -> k, v { [] })
    params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: 1 })
    transformer = TypedParams::Transformer.new(schema:)

    expect { transformer.call(params) }.to raise_error NotImplementedError
  end

  it 'should not delete root param with no key' do
    schema      = TypedParams::Schema.new(type: :hash, transform: -> k, v { [nil, v] })
    params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: 1 })
    transformer = TypedParams::Transformer.new(schema:)

    expect { transformer.call(params) }.to raise_error NotImplementedError
  end

  it 'should not delete root param with no value' do
    schema      = TypedParams::Schema.new(type: :hash, transform: -> k, v { [k, nil] })
    params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: 1 })
    transformer = TypedParams::Transformer.new(schema:)

    expect { transformer.call(params) }.to_not raise_error
  end

  it 'should delete child param with no key or value' do
    schema = TypedParams::Schema.new type: :hash do
      param :foo, type: :hash do
        param :bar, type: :integer, transform: -> k, v { [] }
      end
    end

    params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: { bar: 1 } })
    transformer = TypedParams::Transformer.new(schema:)

    transformer.call(params)

    expect(params[:foo].value).to eq({})
    expect(params[:foo][:bar]).to be nil
  end

  it 'should delete child param with no key' do
    schema = TypedParams::Schema.new type: :hash do
      param :foo, type: :hash do
        param :bar, type: :integer, transform: -> k, v { [nil, v] }
      end
    end

    params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: { bar: 1 } })
    transformer = TypedParams::Transformer.new(schema:)

    transformer.call(params)

    expect(params[:foo].value).to eq({})
    expect(params[:foo][:bar]).to be nil
  end

  it 'should not delete child param with no value' do
    schema = TypedParams::Schema.new type: :hash do
      param :foo, type: :hash do
        param :bar, type: :integer, transform: -> k, v { [k, nil] }
      end
    end

    params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: { bar: 1 } })
    transformer = TypedParams::Transformer.new(schema:)

    transformer.call(params)

    expect(params[:foo].value).to_not be_empty
    expect(params[:foo][:bar].value).to be nil
  end

  it 'should not transform blank param to nil' do
    schema      = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, nilify_blanks: false }
    params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: '' })
    transformer = TypedParams::Transformer.new(schema:)

    transformer.call(params)

    expect(params[:foo].value).to eq ''
  end

  it 'should transform blank param to nil' do
    schema      = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, nilify_blanks: true }
    params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: '' })
    transformer = TypedParams::Transformer.new(schema:)

    transformer.call(params)

    expect(params[:foo].value).to be nil
  end

  it 'should not remove noop param' do
    schema      = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, noop: false }
    params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'bar' })
    transformer = TypedParams::Transformer.new(schema:)

    transformer.call(params)

    expect(params[:foo]).to_not be nil
  end

  it 'should remove noop param' do
    schema      = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, noop: true }
    params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'bar' })
    transformer = TypedParams::Transformer.new(schema:)

    transformer.call(params)

    expect(params[:foo]).to be nil
  end

  it 'should rename aliased param' do
    schema      = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, as: :bar }
    params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'baz' })
    transformer = TypedParams::Transformer.new(schema:)

    transformer.call(params)

    expect(params[:foo]).to be nil
    expect(params[:bar].value).to be 'baz'
  end

  it 'should rename multiple aliased params' do
    schema = TypedParams::Schema.new type: :hash do
      param :foo, type: :integer, as: :qux
      param :bar, type: :integer, as: :qux
      param :baz, type: :integer, as: :qux
    end

    params      = TypedParams::Parameterizer.new(schema:).call(value: { bar: 2, foo: 1 })
    transformer = TypedParams::Transformer.new(schema:)

    transformer.call(params)

    expect(params[:foo]).to be nil
    expect(params[:bar]).to be nil
    expect(params[:baz]).to be nil
    expect(params[:qux].value).to be 2
  end

  context 'with config to not ignore optional nils' do
    before do
      @ignore_nil_optionals = TypedParams.config.ignore_nil_optionals

      TypedParams.config.ignore_nil_optionals = false
    end

    after do
      TypedParams.config.ignore_nil_optionals = @ignore_nil_optionals_was
    end

    it 'should not delete required nil param' do
      schema      = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false, optional: false }
      params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: nil })
      transformer = TypedParams::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:foo]).to_not be nil
    end

    it 'should not delete optional nil param when allowed' do
      schema      = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: true, optional: true }
      params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: nil })
      transformer = TypedParams::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:foo]).to_not be nil
    end

    it 'should not delete optional nil param' do
      schema      = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false, optional: true }
      params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: nil })
      transformer = TypedParams::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:foo]).to_not be nil
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

    it 'should not delete required nil param' do
      schema      = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false, optional: false }
      params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: nil })
      transformer = TypedParams::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:foo]).to_not be nil
    end

    it 'should not delete optional nil param when allowed' do
      schema      = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: true, optional: true }
      params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: nil })
      transformer = TypedParams::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:foo]).to_not be nil
    end

    it 'should delete optional nil param' do
      schema      = TypedParams::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false, optional: true }
      params      = TypedParams::Parameterizer.new(schema:).call(value: { foo: nil })
      transformer = TypedParams::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:foo]).to be nil
    end
  end
end