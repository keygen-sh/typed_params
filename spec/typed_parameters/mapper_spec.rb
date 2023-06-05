# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Mapper do
  let :schema do
    TypedParameters::Schema.new type: :hash do
      param :foo, type: :hash do
        param :bar, type: :array do
          items type: :hash do
            param :baz, type: :integer
          end
        end
        param :qux, type: :array do
          items type: :hash do
            param :quux, type: :integer
          end
        end
      end
    end
  end

  it 'should use depth-first algorithm' do
    params = TypedParameters::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 0 }, { baz: 1 }, { baz: 2 }], qux: [{ quux: 0 }, { quux: 1 }, { quux: 2 }] } })
    order  = []

    rule = Class.new(TypedParameters::Mapper) do
      define_method :call do |params|
        depth_first_map(params) { order << _1.path.to_json_pointer }
      end
    end

    rule.new(schema:).call(params)

    expect(order).to eq [
      '/foo/bar/0/baz',
      '/foo/bar/0',
      '/foo/bar/1/baz',
      '/foo/bar/1',
      '/foo/bar/2/baz',
      '/foo/bar/2',
      '/foo/bar',
      '/foo/qux/0/quux',
      '/foo/qux/0',
      '/foo/qux/1/quux',
      '/foo/qux/1',
      '/foo/qux/2/quux',
      '/foo/qux/2',
      '/foo/qux',
      '/foo',
      '/',
    ]
  end
end