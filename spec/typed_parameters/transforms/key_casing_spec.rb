# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Transforms::KeyCasing do
  let(:transform) { TypedParameters::Transforms::KeyCasing.new(casing) }
  let(:casing)    { TypedParameters.config.key_transform }

  context 'with no key transform' do
    %w[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      it "should not transform key: #{key.inspect}" do
        k, v = transform.call(key, { key => 'baz' })

        expect(k).to eq key
        expect(v).to eq key => 'baz'
      end
    end

    %i[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      it "should not transform key: #{key.inspect}" do
        k, v = transform.call(key, { key => :baz })

        expect(k).to eq key
        expect(v).to eq key => :baz
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
      it "should transform key: #{key.inspect}" do
        k, v = transform.call(key, { key => 'baz' })

        expect(k).to eq 'foo_bar'
        expect(v).to eq k => 'baz'
      end
    end

    %i[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      it "should transform key: #{key.inspect}" do
        k, v = transform.call(key, { key => :baz })

        expect(k).to eq :foo_bar
        expect(v).to eq k => :baz
      end
    end

    it 'should transform shallow array' do
      k, v = transform.call('rootKey', %w[a_value another_value])

      expect(k).to eq 'root_key'
      expect(v).to eq %w[a_value another_value]
    end

    it 'should transform deep array' do
      k, v = transform.call(
        'rootKey',
        [
          'child_value',
          {
            'childKey' => [
              { 'grandchildKey' => { 'greatGrandchildKey' => %i[a_value another_value] } },
              { 'grandchildKey' => { 'greatGrandchildKey' => %s[a_value another_value] } },
            ],
          },
          :child_value,
          {
            'childKey' => [
              { 'grandchildKey' => { 'greatGrandchildKey' => [1, 2, 3] } },
            ],
          },
          1,
        ],
      )

      expect(k).to eq 'root_key'
      expect(v).to eq [
        'child_value',
        {
          'child_key' => [
            { 'grandchild_key' => { 'great_grandchild_key' => %i[a_value another_value] } },
            { 'grandchild_key' => { 'great_grandchild_key' => %s[a_value another_value] } },
          ],
        },
        :child_value,
        {
          'child_key' => [
            { 'grandchild_key' => { 'great_grandchild_key' => [1, 2, 3] } },
          ],
        },
        1,
      ]
    end

    it 'should transform shallow hash' do
      k, v = transform.call(:rootKey, { aKey: :a_value, anotherKey: :another_value })

      expect(k).to eq :root_key
      expect(v).to eq a_key: :a_value, another_key: :another_value
    end

    it 'should transform deep hash' do
      k, v = transform.call(
        :rootKey,
        {
          childKey: [
            { grandchildKey: { greatGrandchildKey: %i[a_value another_value] } },
            'grandchild_value',
            { grandchildKey: { greatGrandchildKey: %s[a_value another_value] } },
            :grandchild_value,
            { grandchildKey: { greatGrandchildKey: [1, 2, 3] } },
            1,
          ]
        },
      )

      expect(k).to eq :root_key
      expect(v).to eq child_key: [
        { grandchild_key: { great_grandchild_key: %i[a_value another_value] } },
        'grandchild_value',
        { grandchild_key: { great_grandchild_key: %s[a_value another_value] } },
        :grandchild_value,
        { grandchild_key: { great_grandchild_key: [1, 2, 3] } },
        1,
      ]
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
      it "should transform key: #{key.inspect}" do
        k, v = transform.call(key, { key => 'baz' })

        expect(k).to eq 'FooBar'
        expect(v).to eq k => 'baz'
      end
    end

    %i[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      it "should transform key: #{key.inspect}" do
        k, v = transform.call(key, { key => :baz })

        expect(k).to eq :FooBar
        expect(v).to eq k => :baz
      end
    end

    it 'should transform shallow array' do
      k, v = transform.call('root_key', %w[a_value another_value])

      expect(k).to eq 'RootKey'
      expect(v).to eq %w[a_value another_value]
    end

    it 'should transform deep array' do
      k, v = transform.call(
        'root_key',
        [
          'child_value',
          {
            'child_key' => [
              { 'grandchild_key' => { 'great_grandchild_key' => %i[a_value another_value] } },
              { 'grandchild_key' => { 'great_grandchild_key' => %s[a_value another_value] } },
            ],
          },
          :child_value,
          {
            'child_key' => [
              { 'grandchild_key' => { 'great_grandchild_key' => [1, 2, 3] } },
            ],
          },
          1,
        ],
      )

      expect(k).to eq 'RootKey'
      expect(v).to eq [
        'child_value',
        {
          'ChildKey' => [
            { 'GrandchildKey' => { 'GreatGrandchildKey' => %i[a_value another_value] } },
            { 'GrandchildKey' => { 'GreatGrandchildKey' => %s[a_value another_value] } },
          ],
        },
        :child_value,
        {
          'ChildKey' => [
            { 'GrandchildKey' => { 'GreatGrandchildKey' => [1, 2, 3] } },
          ],
        },
        1,
      ]
    end

    it 'should transform shallow hash' do
      k, v = transform.call(:root_key, { a_key: :a_value, another_key: :another_value })

      expect(k).to eq :RootKey
      expect(v).to eq AKey: :a_value, AnotherKey: :another_value
    end

    it 'should transform deep hash' do
      k, v = transform.call(
        :root_key,
        {
          child_key: [
            { grandchild_key: { great_grandchild_key: %i[a_value another_value] } },
            'grandchild_value',
            { grandchild_key: { great_grandchild_key: %s[a_value another_value] } },
            :grandchild_value,
            { grandchild_key: { great_grandchild_key: [1, 2, 3] } },
            1,
          ],
        },
      )

      expect(k).to eq :RootKey
      expect(v).to eq ChildKey: [
        { GrandchildKey: { GreatGrandchildKey: %i[a_value another_value] } },
        'grandchild_value',
        { GrandchildKey: { GreatGrandchildKey: %s[a_value another_value] } },
        :grandchild_value,
        { GrandchildKey: { GreatGrandchildKey: [1, 2, 3] } },
        1,
      ]
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
      it "should transform key: #{key.inspect}" do
        k, v = transform.call(key, { key => 'baz' })

        expect(k).to eq 'fooBar'
        expect(v).to eq k => 'baz'
      end
    end

    %i[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      it "should transform key: #{key.inspect}" do
        k, v = transform.call(key, { key => :baz })

        expect(k).to eq :fooBar
        expect(v).to eq k => :baz
      end
    end

    it 'should transform shallow array' do
      k, v = transform.call('root_key', %w[a_value another_value])

      expect(k).to eq 'rootKey'
      expect(v).to eq %w[a_value another_value]
    end

    it 'should transform deep array' do
      k, v = transform.call(
        'root_key',
        [
          'child_value',
          {
            'child_key' => [
              { 'grandchild_key' => { 'great_grandchild_key' => %i[a_value another_value] } },
              { 'grandchild_key' => { 'great_grandchild_key' => %s[a_value another_value] } },
            ],
          },
          :child_value,
          {
            'child_key' => [
              { 'grandchild_key' => { 'great_grandchild_key' => [1, 2, 3] } },
            ],
          },
          1,
        ],
      )

      expect(k).to eq 'rootKey'
      expect(v).to eq [
        'child_value',
        {
          'childKey' => [
            { 'grandchildKey' => { 'greatGrandchildKey' => %i[a_value another_value] } },
            { 'grandchildKey' => { 'greatGrandchildKey' => %s[a_value another_value] } },
          ],
        },
        :child_value,
        {
          'childKey' => [
            { 'grandchildKey' => { 'greatGrandchildKey' => [1, 2, 3] } },
          ],
        },
        1,
      ]
    end

    it 'should transform shallow hash' do
      k, v = transform.call(:root_key, { a_key: :a_value, another_key: :another_value })

      expect(k).to eq :rootKey
      expect(v).to eq aKey: :a_value, anotherKey: :another_value
    end

    it 'should transform deep hash' do
      k, v = transform.call(
        :root_key,
        {
          child_key: [
            { grandchild_key: { great_grandchild_key: %i[a_value another_value] } },
            'grandchild_value',
            { grandchild_key: { great_grandchild_key: %s[a_value another_value] } },
            :grandchild_value,
            { grandchild_key: { great_grandchild_key: [1, 2, 3] } },
            1,
          ],
        },
      )

      expect(k).to eq :rootKey
      expect(v).to eq childKey: [
        { grandchildKey: { greatGrandchildKey: %i[a_value another_value] } },
        'grandchild_value',
        { grandchildKey: { greatGrandchildKey: %s[a_value another_value] } },
        :grandchild_value,
        { grandchildKey: { greatGrandchildKey: [1, 2, 3] } },
        1,
      ]
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
      it "should transform key: #{key.inspect}" do
        k, v = transform.call(key, { key => 'baz' })

        expect(k).to eq 'foo-bar'
        expect(v).to eq k => 'baz'
      end
    end

    %i[
      foo_bar
      foo-bar
      FooBar
      fooBar
    ].each do |key|
      it "should transform key: #{key.inspect}" do
        k, v = transform.call(key, { key => :baz })

        expect(k).to eq :'foo-bar'
        expect(v).to eq k => :baz
      end
    end

    it 'should transform shallow array' do
      k, v = transform.call('root_key', %w[a_value another_value])

      expect(k).to eq 'root-key'
      expect(v).to eq %w[a_value another_value]
    end

    it 'should transform deep array' do
      k, v = transform.call(
        'root_key',
        [
          'child_value',
          {
            'child_key' => [
              { 'grandchild_key' => { 'great_grandchild_key' => %i[a_value another_value] } },
              { 'grandchild_key' => { 'great_grandchild_key' => %s[a_value another_value] } },
            ],
          },
          :child_value,
          {
            'child_key' => [
              { 'grandchild_key' => { 'great_grandchild_key' => [1, 2, 3] } },
            ],
          },
          1,
        ],
      )

      expect(k).to eq 'root-key'
      expect(v).to eq [
        'child_value',
        {
          'child-key' => [
            { 'grandchild-key' => { 'great-grandchild-key' => %i[a_value another_value] } },
            { 'grandchild-key' => { 'great-grandchild-key' => %s[a_value another_value] } },
          ],
        },
        :child_value,
        {
          'child-key' => [
            { 'grandchild-key' => { 'great-grandchild-key' => [1, 2, 3] } },
          ],
        },
        1,
      ]
    end

    it 'should transform shallow hash' do
      k, v = transform.call(:root_key, { a_key: :a_value, another_key: :another_value })

      expect(k).to eq :'root-key'
      expect(v).to eq 'a-key': :a_value, 'another-key': :another_value
    end

    it 'should transform deep hash' do
      k, v = transform.call(
        :root_key,
        {
          child_key: [
            { grandchild_key: { great_grandchild_key: %i[a_value another_value] } },
            'grandchild_value',
            { grandchild_key: { great_grandchild_key: %s[a_value another_value] } },
            :grandchild_value,
            { grandchild_key: { great_grandchild_key: [1, 2, 3] } },
            1,
          ],
        },
      )

      expect(k).to eq :'root-key'
      expect(v).to eq 'child-key': [
        { 'grandchild-key': { 'great-grandchild-key': %i[a_value another_value] } },
        'grandchild_value',
        { 'grandchild-key': { 'great-grandchild-key': %s[a_value another_value] } },
        :grandchild_value,
        { 'grandchild-key': { 'great-grandchild-key': [1, 2, 3] } },
        1,
      ]
    end
  end

  context 'with config key transform' do
    before { TypedParameters.config.key_transform = :dash }

    it "should transform key" do
      k, v = transform.call(:foo_bar, { :baz_qux => 1 })

      expect(k).to eq :'foo-bar'
      expect(v).to eq :'baz-qux' => 1
    end

  end
end