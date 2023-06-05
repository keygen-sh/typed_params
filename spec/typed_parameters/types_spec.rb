# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Types do
  describe '.register' do
    after { TypedParameters::Types.unregister(:test) }

    it 'should register nominal type' do
      type = TypedParameters::Types.register(:test,
        match: -> v {},
      )

      expect(TypedParameters::Types.types[:test]).to eq type
    end

    it 'should register subtype' do
      type = TypedParameters::Types.register(:test,
        archetype: :symbol,
        match: -> v {},
      )

      expect(TypedParameters::Types.subtypes[:test]).to eq type
    end

    it 'should register abstract type' do
      type = TypedParameters::Types.register(:test,
        abstract: true,
        match: -> v {},
      )

      expect(TypedParameters::Types.abstracts[:test]).to eq type
    end

    it 'should not register a duplicate type' do
      type = TypedParameters::Types.register(:test,
        match: -> v {},
        abstract: true,
      )

      expect { TypedParameters::Types.register(:test, match: -> v {}) }
        .to raise_error ArgumentError
    end
  end

  describe '.unregister' do
    it 'should unregister nominal type' do
      TypedParameters::Types.register(:test, match: -> v {})
      TypedParameters::Types.unregister(:test)

      expect(TypedParameters::Types.types[:test]).to be_nil
    end

    it 'should unregister subtype' do
      TypedParameters::Types.register(:test, archetype: :hash, match: -> v {})
      TypedParameters::Types.unregister(:test)

      expect(TypedParameters::Types.subtypes[:test]).to be_nil
    end

    it 'should unregister abstract type' do
      TypedParameters::Types.register(:test, abstract: true, match: -> v {})
      TypedParameters::Types.unregister(:test)

      expect(TypedParameters::Types.abstracts[:test]).to be_nil
    end
  end

  describe '.for' do
    it 'should fetch type' do
      type = TypedParameters::Types.for(1)

      expect(type.type).to eq :integer
    end

    it 'should not fetch type' do
      expect { TypedParameters::Types.for(Class.new) }.to raise_error ArgumentError
    end

    context 'with custom type' do
      subject { Class.new }

      before { TypedParameters::Types.register(:class, match: -> v { v.is_a?(subject) }) }
      after  { TypedParameters::Types.unregister(:class) }

      it 'should fetch type' do
        type = TypedParameters::Types.for(subject.new)

        expect(type.type).to eq :class
      end
    end

    context 'with subtype' do
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

      it 'should fetch subtype' do
        types = []

        types << TypedParameters::Types.for({ foo: 1, bar: 2 }, try: %i[shallow_hash])
        types << TypedParameters::Types.for({ foo: 1, bar: 2 }, try: :shallow_hash)

        types.each do |type|
          expect(type.type).to eq :shallow_hash
          expect(type.subtype?).to be true
          expect(type.archetype.type).to eq :hash
        end
      end

      it 'should not fetch subtype' do
        types = []

        types << TypedParameters::Types.for({ foo: 1, bar: 2 }, try: [])
        types << TypedParameters::Types.for({ foo: 1, bar: 2 })
        types << TypedParameters::Types.for({ baz: [1], qux: { a: 2 } }, try: %i[shallow_hash])
        types << TypedParameters::Types.for({ baz: [1], qux: { a: 2 } }, try: :shallow_hash)
        types << TypedParameters::Types.for({ baz: [1], qux: { a: 2 } }, try: nil)

        types.each do |type|
          expect(type.type).to eq :hash
          expect(type.subtype?).to be false
        end
      end
    end
  end

  describe '.[]' do
    it 'should fetch type by key' do
      type = TypedParameters::Types[:string]

      expect(type.type).to eq :string
    end
  end

  describe :boolean do
    let(:type) { TypedParameters.types[:boolean] }

    it 'should match' do
      expect(type.match?(true)).to be true
      expect(type.match?(false)).to be true
    end

    it 'should not match' do
      expect(type.match?(nil)).to be false
      expect(type.match?({})).to be false
      expect(type.match?('')).to be false
      expect(type.match?(1)).to be false
    end

    it 'should find' do
      t = TypedParameters.types.for(true)
      f = TypedParameters.types.for(false)

      expect(t.type).to eq :boolean
      expect(f.type).to eq :boolean
    end
  end

  describe :string do
    let(:type) { TypedParameters.types[:string] }

    it 'should match' do
      expect(type.match?('foo')).to be true
    end

    it 'should not match' do
      expect(type.match?(true)).to be false
      expect(type.match?(nil)).to be false
      expect(type.match?({})).to be false
      expect(type.match?(1)).to be false
    end

    it 'should find' do
      t = TypedParameters.types.for('foo')

      expect(t.type).to eq :string
    end
  end

  describe :symbol do
    let(:type) { TypedParameters.types[:symbol] }

    it 'should match' do
      expect(type.match?(:foo)).to be true
    end

    it 'should not match' do
      expect(type.match?(true)).to be false
      expect(type.match?(nil)).to be false
      expect(type.match?({})).to be false
      expect(type.match?('')).to be false
      expect(type.match?(1)).to be false
    end

    it 'should find' do
      t = TypedParameters.types.for(:foo)

      expect(t.type).to eq :symbol
    end
  end

  describe :integer do
    let(:type) { TypedParameters.types[:integer] }

    it 'should match' do
      expect(type.match?(1)).to be true
    end

    it 'should not match' do
      expect(type.match?(true)).to be false
      expect(type.match?(nil)).to be false
      expect(type.match?(1.0)).to be false
      expect(type.match?({})).to be false
      expect(type.match?('')).to be false
    end

    it 'should find' do
      t = TypedParameters.types.for(1)

      expect(t.type).to eq :integer
    end
  end

  describe :float do
    let(:type) { TypedParameters.types[:float] }

    it 'should match' do
      expect(type.match?(2.0)).to be true
    end

    it 'should not match' do
      expect(type.match?(true)).to be false
      expect(type.match?(nil)).to be false
      expect(type.match?({})).to be false
      expect(type.match?('')).to be false
      expect(type.match?(1)).to be false
    end

    it 'should find' do
      t = TypedParameters.types.for(1.0)

      expect(t.type).to eq :float
    end
  end

  describe :decimal do
    let(:type) { TypedParameters.types[:decimal] }

    it 'should match' do
      expect(type.match?(2.0.to_d)).to be true
    end

    it 'should not match' do
      expect(type.match?(true)).to be false
      expect(type.match?(nil)).to be false
      expect(type.match?({})).to be false
      expect(type.match?('')).to be false
      expect(type.match?(1)).to be false
      expect(type.match?(1.0)).to be false
    end

    it 'should find' do
      t = TypedParameters.types.for(1.0.to_d)

      expect(t.type).to eq :decimal
    end
  end

  describe :number do
    let(:type) { TypedParameters.types[:number] }

    it 'should match' do
      expect(type.match?(2.0)).to be true
      expect(type.match?(1)).to be true
    end

    it 'should not match' do
      expect(type.match?(true)).to be false
      expect(type.match?(nil)).to be false
      expect(type.match?({})).to be false
      expect(type.match?('')).to be false
    end

    it 'should not find' do
      integer = TypedParameters.types.for(1)
      float   = TypedParameters.types.for(1.0)

      expect(integer.type).to_not eq :number
      expect(float.type).to_not eq :number
    end
  end

  describe :array do
    let(:type) { TypedParameters.types[:array] }

    it 'should match' do
      expect(type.match?([])).to be true
      expect(type.match?([1])).to be true
      expect(type.match?([''])).to be true
    end

    it 'should not match' do
      expect(type.match?(true)).to be false
      expect(type.match?(nil)).to be false
      expect(type.match?({})).to be false
      expect(type.match?('')).to be false
      expect(type.match?(1)).to be false
    end

    it 'should find' do
      t = TypedParameters.types.for([])

      expect(t.type).to eq :array
    end
  end

  describe :hash do
    let(:type) { TypedParameters.types[:hash] }

    it 'should match' do
      expect(type.match?({})).to be true
      expect(type.match?({ foo: {} })).to be true
      expect(type.match?({ bar: 1 })).to be true
    end

    it 'should not match' do
      expect(type.match?(true)).to be false
      expect(type.match?(nil)).to be false
      expect(type.match?([])).to be false
      expect(type.match?('')).to be false
      expect(type.match?(1)).to be false
    end

    it 'should find' do
      t = TypedParameters.types.for({})

      expect(t.type).to eq :hash
    end
  end

  describe :date do
    let(:type) { TypedParameters.types[:date] }

    it 'should match' do
      expect(type.match?(Date.today)).to be true
    end

    it 'should not match' do
      expect(type.match?(true)).to be false
      expect(type.match?(nil)).to be false
      expect(type.match?([])).to be false
      expect(type.match?('')).to be false
      expect(type.match?(1)).to be false
      expect(type.match?(Date.today.to_s)).to be false
      expect(type.match?(Time.now)).to be false
    end

    it 'should find' do
      t = TypedParameters.types.for(Date.today)

      expect(t.type).to eq :date
    end
  end

  describe :time do
    let(:type) { TypedParameters.types[:time] }

    it 'should match' do
      expect(type.match?(Time.now)).to be true
    end

    it 'should not match' do
      expect(type.match?(true)).to be false
      expect(type.match?(nil)).to be false
      expect(type.match?([])).to be false
      expect(type.match?('')).to be false
      expect(type.match?(1)).to be false
      expect(type.match?(Time.now.to_s)).to be false
      expect(type.match?(Date.today)).to be false
    end

    it 'should find' do
      t = TypedParameters.types.for(Time.now)

      expect(t.type).to eq :time
    end
  end

  describe :nil do
    let(:type) { TypedParameters.types[:nil] }

    it 'should match' do
      expect(type.match?(nil)).to be true
    end

    it 'should not match' do
      expect(type.match?(true)).to be false
      expect(type.match?({})).to be false
      expect(type.match?([])).to be false
      expect(type.match?('')).to be false
      expect(type.match?(1)).to be false
    end

    it 'should find' do
      t = TypedParameters.types.for(nil)

      expect(t.type).to eq :nil
    end
  end
end