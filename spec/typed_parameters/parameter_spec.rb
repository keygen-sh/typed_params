# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Parameter do
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

  it 'should delegate missing methods to value' do
    params = TypedParameters::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 0 }, { baz: 1 }] } })
    orig   = params.dup

    expect { params.stringify_keys! }.to_not raise_error
    expect { params.fetch(:foo) }.to raise_error KeyError
    expect { params.fetch('foo') }.to_not raise_error
    expect { params.merge!(qux: 2) }.to_not raise_error
    expect { params.fetch(:qux) }.to_not raise_error
    expect { params.reject! { _1 == :qux } }.to_not raise_error
    expect { params.fetch(:qux) }.to raise_error KeyError
    expect { params.symbolize_keys! }.to_not raise_error

    expect(params.value).to eq orig.value
  end

  describe '#delete' do
    it 'should not delete root param' do
      params = TypedParameters::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 0 }, { baz: 1 }] } })

      expect { params.delete }.to raise_error NotImplementedError
    end

    it 'should delete child param' do
      params = TypedParameters::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 0 }, { baz: 1 }] } })

      expect { params[:foo].delete }.to_not raise_error
      expect(params[:foo]).to be nil
    end

    it 'should delete grandchild param' do
      params = TypedParameters::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 0 }, { baz: 1 }] } })

      expect { params[:foo][:bar].delete }.to_not raise_error
      expect(params[:foo][:bar]).to be nil
    end

    it 'should delete great grandchild param' do
      params = TypedParameters::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 0 }, { baz: 1 }] } })

      expect { params[:foo][:bar][1].delete }.to_not raise_error
      expect(params[:foo][:bar][0]).to_not be nil
      expect(params[:foo][:bar][1]).to be nil
    end
  end

  describe '#path' do
    it 'should have correct path' do
      params = TypedParameters::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 0 }, { baz: 1 }] } })

      expect(params[:foo][:bar][0][:baz].path.to_json_pointer).to eq '/foo/bar/0/baz'
      expect(params[:foo][:bar][1][:baz].path.to_json_pointer).to eq '/foo/bar/1/baz'
    end
  end

  describe '#keys' do
    context 'with array schema' do
      let(:schema) { TypedParameters::Schema.new(type: :array) { items type: :string } }

      it 'should have correct keys' do
        params = TypedParameters::Parameterizer.new(schema:).call(value: %w[a b c])

        expect(params.keys).to eq [0, 1, 2]
      end

      it 'should have no keys' do
        params = TypedParameters::Parameterizer.new(schema:).call(value: [])

        expect(params.keys).to eq []
      end
    end

    context 'with hash schema' do
      let(:schema) { TypedParameters::Schema.new(type: :hash) { params :a, :b, :c, type: :string } }

      it 'should have correct keys' do
        params = TypedParameters::Parameterizer.new(schema:).call(value: { a: 1, b: 2, c: 3 })

        expect(params.keys).to eq %i[a b c]
      end

      it 'should have no keys' do
        params = TypedParameters::Parameterizer.new(schema:).call(value: {})

        expect(params.keys).to eq []
      end
    end

    context 'with other schema' do
      let(:schema) { TypedParameters::Schema.new(type: :integer) }

      it 'should have no keys' do
        params = TypedParameters::Parameterizer.new(schema:).call(value: 1)

        expect(params.keys).to eq []
      end
    end
  end
end