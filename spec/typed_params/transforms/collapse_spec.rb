# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Transforms::Collapse do
  context 'with default options' do
    let(:transform) { TypedParams::Transforms::Collapse.new(true) }

    it 'should combine keys with parent_child format' do
      schema = TypedParams::Schema.new(type: :hash) { param(:resource, type: :hash) { param :type, type: :string } }
      params = TypedParams::Parameterizer.new(schema:).call(value: { resource: { type: 'users' } })

      transform.call(params[:resource])

      expect(params[:resource]).to be nil
      expect(params[:resource_type].key).to eq :resource_type
      expect(params[:resource_type].value).to eq 'users'
    end

    it 'should preserve nested value' do
      schema = TypedParams::Schema.new(type: :hash) { param(:foo, type: :hash) { param :bar, type: :hash } }
      params = TypedParams::Parameterizer.new(schema:).call(value: { foo: { bar: { nested: 'value' } } })

      transform.call(params[:foo])

      expect(params[:foo_bar].value).to eq nested: 'value'
    end
  end

  context 'with :parent_child format' do
    let(:transform) { TypedParams::Transforms::Collapse.new(format: :parent_child) }

    it 'should combine keys with parent first' do
      schema = TypedParams::Schema.new(type: :hash) { param(:resource, type: :hash) { param :type, type: :string } }
      params = TypedParams::Parameterizer.new(schema:).call(value: { resource: { type: 'users' } })

      transform.call(params[:resource])

      expect(params[:resource_type].key).to eq :resource_type
    end

    it 'should combine keys with parent first for id' do
      schema = TypedParams::Schema.new(type: :hash) { param(:resource, type: :hash) { param :id, type: :string } }
      params = TypedParams::Parameterizer.new(schema:).call(value: { resource: { id: '123' } })

      transform.call(params[:resource])

      expect(params[:resource_id].key).to eq :resource_id
    end
  end

  context 'with :child_parent format' do
    let(:transform) { TypedParams::Transforms::Collapse.new(format: :child_parent) }

    it 'should combine keys with child first' do
      schema = TypedParams::Schema.new(type: :hash) { param(:date, type: :hash) { param :start, type: :string } }
      params = TypedParams::Parameterizer.new(schema:).call(value: { date: { start: '2024-01-01' } })

      transform.call(params[:date])

      expect(params[:start_date].key).to eq :start_date
    end

    it 'should combine keys with child first for end' do
      schema = TypedParams::Schema.new(type: :hash) { param(:date, type: :hash) { param :end, type: :string } }
      params = TypedParams::Parameterizer.new(schema:).call(value: { date: { end: '2024-12-31' } })

      transform.call(params[:date])

      expect(params[:end_date].key).to eq :end_date
    end
  end

  context 'with :child format' do
    let(:transform) { TypedParams::Transforms::Collapse.new(format: :child) }

    it 'should use child key verbatim' do
      schema = TypedParams::Schema.new(type: :hash) { param(:resource, type: :hash) { param :type, type: :string } }
      params = TypedParams::Parameterizer.new(schema:).call(value: { resource: { type: 'users' } })

      transform.call(params[:resource])

      expect(params[:type].key).to eq :type
      expect(params[:type].value).to eq 'users'
    end

    it 'should collapse multiple children' do
      schema = TypedParams::Schema.new(type: :hash) { param(:resource, type: :hash) { param :id, type: :string; param :type, type: :string } }
      params = TypedParams::Parameterizer.new(schema:).call(value: { resource: { id: '123', type: 'users' } })

      transform.call(params[:resource])

      expect(params[:id].key).to eq :id
      expect(params[:id].value).to eq '123'
      expect(params[:type].key).to eq :type
      expect(params[:type].value).to eq 'users'
    end
  end

  context 'with invalid format' do
    it 'should raise' do
      expect { TypedParams::Transforms::Collapse.new(format: :invalid) }.to(
        raise_error NoMatchingPatternError
      )
    end
  end

  context 'with custom transformer' do
    let(:transform) { TypedParams::Transforms::Collapse.new(transformer) }

    context 'with simple lambda' do
      let(:transformer) { ->(pk, pv, ck, cv) { [:"#{ck}_#{pk}", cv] } }

      it 'should use custom key combination' do
        schema = TypedParams::Schema.new(type: :hash) { param(:resource, type: :hash) { param :type, type: :string } }
        params = TypedParams::Parameterizer.new(schema:).call(value: { resource: { type: 'users' } })

        transform.call(params[:resource])

        expect(params[:type_resource].key).to eq :type_resource
      end
    end

    context 'with value-transforming lambda' do
      let(:transformer) { ->(pk, pv, ck, cv) { [:"#{pk}_#{ck}", cv.upcase] } }

      it 'should transform value' do
        schema = TypedParams::Schema.new(type: :hash) { param(:resource, type: :hash) { param :type, type: :string } }
        params = TypedParams::Parameterizer.new(schema:).call(value: { resource: { type: 'users' } })

        transform.call(params[:resource])

        expect(params[:resource_type].value).to eq 'USERS'
      end
    end

    context 'with custom separator' do
      let(:transformer) { ->(pk, pv, ck, cv) { [:"#{pk}-#{ck}", cv] } }

      it 'should use custom separator' do
        schema = TypedParams::Schema.new(type: :hash) { param(:resource, type: :hash) { param :type, type: :string } }
        params = TypedParams::Parameterizer.new(schema:).call(value: { resource: { type: 'users' } })

        transform.call(params[:resource])

        expect(params[:'resource-type'].key).to eq :'resource-type'
      end
    end
  end
end
