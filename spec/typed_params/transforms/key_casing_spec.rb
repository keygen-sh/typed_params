# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Transforms::KeyCasing do
  let(:transform) { TypedParams::Transforms::KeyCasing.new(casing) }
  let(:casing)    { TypedParams.config.key_transform }

  context 'with no key transform' do
    %w[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      context "with string key #{key.inspect}" do
        it 'should not transform key' do
          schema = TypedParams::Schema.new(type: :hash) { param key, type: :hash }
          params = TypedParams::Parameterizer.new(schema:).call(
            value: { key => { key => 'baz' } },
          )

          transform.call(params[key])

          expect(params[key].key).to eq key
          expect(params[key].value).to eq key => 'baz'
        end
      end
    end

    %i[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      context "with symbol key #{key.inspect}" do
        it 'should not transform key' do
          schema = TypedParams::Schema.new(type: :hash) { param key, type: :hash }
          params = TypedParams::Parameterizer.new(schema:).call(
            value: { key => { key => :baz } },
          )

          transform.call(params[key])

          expect(params[key].key).to eq key
          expect(params[key].value).to eq key => :baz
        end
      end
    end
  end

  context 'with :underscore key transform' do
    let(:casing) { :underscore }

    %w[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      context "with string key #{key.inspect}" do
        it 'should transform key' do
          schema = TypedParams::Schema.new(type: :hash) { param key, type: :hash }
          params = TypedParams::Parameterizer.new(schema:).call(
            value: { key => { key => 'baz' } },
          )

          transform.call(params[key])

          expect(params['foo_bar'].key).to eq 'foo_bar'
          expect(params['foo_bar'].value).to eq 'foo_bar' => 'baz'
        end
      end
    end

    %i[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      context "with symbol key #{key.inspect}" do
        it 'should transform key' do
          schema = TypedParams::Schema.new(type: :hash) { param key, type: :hash }
          params = TypedParams::Parameterizer.new(schema:).call(
            value: { key => { key => :baz } },
          )

          transform.call(params[key])

          expect(params[:foo_bar].key).to eq :foo_bar
          expect(params[:foo_bar].value).to eq foo_bar: :baz
        end
      end
    end

    context 'with shallow array value' do
      it 'should transform key but not array values' do
        schema = TypedParams::Schema.new(type: :hash) { param :rootKey, type: :array }
        params = TypedParams::Parameterizer.new(schema:).call(\
          value: {
            rootKey: %w[a_value another_value],
          },
        )

        transform.call(params[:rootKey])

        expect(params[:root_key].key).to eq :root_key
        expect(params[:root_key].value).to eq %w[a_value another_value]
      end
    end

    context 'with deep array value' do
      it 'should transform nested hash keys' do
        schema = TypedParams::Schema.new(type: :hash) { param :rootKey, type: :array }
        params = TypedParams::Parameterizer.new(schema:).call(
          value: {
            rootKey: [
              'child_value',
              { 'childKey' => [{ 'grandchildKey' => { 'greatGrandchildKey' => %i[a_value another_value] } }] },
            ],
          },
        )

        transform.call(params[:rootKey])

        expect(params[:root_key].key).to eq :root_key
        expect(params[:root_key].value).to eq [
          'child_value',
          { 'child_key' => [{ 'grandchild_key' => { 'great_grandchild_key' => %i[a_value another_value] } }] },
        ]
      end
    end

    context 'with shallow hash value' do
      it 'should transform key and nested keys' do
        schema = TypedParams::Schema.new(type: :hash) { param :rootKey, type: :hash }
        params = TypedParams::Parameterizer.new(schema:).call(
          value: {
            rootKey: { aKey: :a_value, anotherKey: :another_value },
          },
        )

        transform.call(params[:rootKey])

        expect(params[:root_key].key).to eq :root_key
        expect(params[:root_key].value).to eq a_key: :a_value, another_key: :another_value
      end
    end

    context 'with deep hash value' do
      it 'should transform nested hash keys' do
        schema = TypedParams::Schema.new(type: :hash) { param :rootKey, type: :hash }
        params = TypedParams::Parameterizer.new(schema:).call(
          value: {
            rootKey: {
              childKey: [{ grandchildKey: { greatGrandchildKey: %i[a_value another_value] } }],
            },
          },
        )

        transform.call(params[:rootKey])

        expect(params[:root_key].key).to eq :root_key
        expect(params[:root_key].value).to eq child_key: [{ grandchild_key: { great_grandchild_key: %i[a_value another_value] } }]
      end
    end
  end

  context 'with :camel key transform' do
    let(:casing) { :camel }

    %w[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      context "with string key #{key.inspect}" do
        it 'should transform key' do
          schema = TypedParams::Schema.new(type: :hash) { param key, type: :hash }
          params = TypedParams::Parameterizer.new(schema:).call(
            value: { key => { key => 'baz' } },
          )

          transform.call(params[key])

          expect(params['FooBar'].key).to eq 'FooBar'
        end
      end
    end

    %i[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      context "with symbol key #{key.inspect}" do
        it 'should transform key' do
          schema = TypedParams::Schema.new(type: :hash) { param key, type: :hash }
          params = TypedParams::Parameterizer.new(schema:).call(
            value: { key => { key => :baz } },
          )

          transform.call(params[key])

          expect(params[:FooBar].key).to eq :FooBar
        end
      end
    end

    context 'with shallow hash value' do
      it 'should transform key and nested keys' do
        schema = TypedParams::Schema.new(type: :hash) { param :root_key, type: :hash }
        params = TypedParams::Parameterizer.new(schema:).call(
          value: {
            root_key: { a_key: :a_value, another_key: :another_value },
          },
        )

        transform.call(params[:root_key])

        expect(params[:RootKey].key).to eq :RootKey
        expect(params[:RootKey].value).to eq AKey: :a_value, AnotherKey: :another_value
      end
    end
  end

  context 'with :lower_camel key transform' do
    let(:casing) { :lower_camel }

    %w[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      context "with string key #{key.inspect}" do
        it 'should transform key' do
          schema = TypedParams::Schema.new(type: :hash) { param key, type: :hash }
          params = TypedParams::Parameterizer.new(schema:).call(
            value: { key => { key => 'baz' } },
          )

          transform.call(params[key])

          expect(params['fooBar'].key).to eq 'fooBar'
        end
      end
    end

    %i[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      context "with symbol key #{key.inspect}" do
        it 'should transform key' do
          schema = TypedParams::Schema.new(type: :hash) { param key, type: :hash }
          params = TypedParams::Parameterizer.new(schema:).call(
            value: { key => { key => :baz } },
          )

          transform.call(params[key])

          expect(params[:fooBar].key).to eq :fooBar
        end
      end
    end

    context 'with shallow hash value' do
      it 'should transform key and nested keys' do
        schema = TypedParams::Schema.new(type: :hash) { param :root_key, type: :hash }
        params = TypedParams::Parameterizer.new(schema:).call(
          value: {
            root_key: { a_key: :a_value, another_key: :another_value },
          },
        )

        transform.call(params[:root_key])

        expect(params[:rootKey].key).to eq :rootKey
        expect(params[:rootKey].value).to eq aKey: :a_value, anotherKey: :another_value
      end
    end
  end

  context 'with :dash key transform' do
    let(:casing) { :dash }

    %w[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      context "with string key #{key.inspect}" do
        it 'should transform key' do
          schema = TypedParams::Schema.new(type: :hash) { param key, type: :hash }
          params = TypedParams::Parameterizer.new(schema:).call(
            value: { key => { key => 'baz' } },
          )

          transform.call(params[key])

          expect(params['foo-bar'].key).to eq 'foo-bar'
        end
      end
    end

    %i[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      context "with symbol key #{key.inspect}" do
        it 'should transform key' do
          schema = TypedParams::Schema.new(type: :hash) { param key, type: :hash }
          params = TypedParams::Parameterizer.new(schema:).call(
            value: { key => { key => :baz } },
          )

          transform.call(params[key])

          expect(params[:'foo-bar'].key).to eq :'foo-bar'
        end
      end
    end

    context 'with shallow hash value' do
      it 'should transform key and nested keys' do
        schema = TypedParams::Schema.new(type: :hash) { param :root_key, type: :hash }
        params = TypedParams::Parameterizer.new(schema:).call(
          value: {
            root_key: { a_key: :a_value, another_key: :another_value },
          },
        )

        transform.call(params[:root_key])

        expect(params[:'root-key'].key).to eq :'root-key'
        expect(params[:'root-key'].value).to eq 'a-key': :a_value, 'another-key': :another_value
      end
    end
  end

  context 'with config key transform' do
    before { TypedParams.config.key_transform = :dash }

    it 'should transform key using config' do
      schema = TypedParams::Schema.new(type: :hash) { param :foo_bar, type: :hash }
      params = TypedParams::Parameterizer.new(schema:).call(
        value: { foo_bar: { baz_qux: 1 } },
      )

      transform.call(params[:foo_bar])

      expect(params[:'foo-bar'].key).to eq :'foo-bar'
      expect(params[:'foo-bar'].value).to eq 'baz-qux': 1
    end
  end
end
