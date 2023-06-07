# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Types do
  describe '.register' do
    after { TypedParams::Types.unregister(:test) }

    it 'should register nominal type' do
      type = TypedParams::Types.register(:test,
        match: -> v {},
      )

      expect(TypedParams::Types.types[:test]).to eq type
    end

    it 'should register subtype' do
      type = TypedParams::Types.register(:test,
        archetype: :symbol,
        match: -> v {},
      )

      expect(TypedParams::Types.subtypes[:test]).to eq type
    end

    it 'should register abstract type' do
      type = TypedParams::Types.register(:test,
        abstract: true,
        match: -> v {},
      )

      expect(TypedParams::Types.abstracts[:test]).to eq type
    end

    it 'should not register a duplicate type' do
      type = TypedParams::Types.register(:test,
        match: -> v {},
        abstract: true,
      )

      expect { TypedParams::Types.register(:test, match: -> v {}) }
        .to raise_error ArgumentError
    end
  end

  describe '.unregister' do
    it 'should unregister nominal type' do
      TypedParams::Types.register(:test, match: -> v {})
      TypedParams::Types.unregister(:test)

      expect(TypedParams::Types.types[:test]).to be_nil
    end

    it 'should unregister subtype' do
      TypedParams::Types.register(:test, archetype: :hash, match: -> v {})
      TypedParams::Types.unregister(:test)

      expect(TypedParams::Types.subtypes[:test]).to be_nil
    end

    it 'should unregister abstract type' do
      TypedParams::Types.register(:test, abstract: true, match: -> v {})
      TypedParams::Types.unregister(:test)

      expect(TypedParams::Types.abstracts[:test]).to be_nil
    end
  end

  describe '.for' do
    it 'should fetch type' do
      type = TypedParams::Types.for(1)

      expect(type.type).to eq :integer
    end

    it 'should not fetch type' do
      expect { TypedParams::Types.for(Class.new) }.to raise_error ArgumentError
    end

    context 'with custom type' do
      subject { Class.new }

      before { TypedParams::Types.register(:class, match: -> v { v.is_a?(subject) }) }
      after  { TypedParams::Types.unregister(:class) }

      it 'should fetch type' do
        type = TypedParams::Types.for(subject.new)

        expect(type.type).to eq :class
      end
    end

    context 'with subtype' do
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

      it 'should fetch subtype' do
        types = []

        types << TypedParams::Types.for({ foo: 1, bar: 2 }, try: %i[shallow_hash])
        types << TypedParams::Types.for({ foo: 1, bar: 2 }, try: :shallow_hash)

        types.each do |type|
          expect(type.type).to eq :shallow_hash
          expect(type.subtype?).to be true
          expect(type.archetype.type).to eq :hash
        end
      end

      it 'should not fetch subtype' do
        types = []

        types << TypedParams::Types.for({ foo: 1, bar: 2 }, try: [])
        types << TypedParams::Types.for({ foo: 1, bar: 2 })
        types << TypedParams::Types.for({ baz: [1], qux: { a: 2 } }, try: %i[shallow_hash])
        types << TypedParams::Types.for({ baz: [1], qux: { a: 2 } }, try: :shallow_hash)
        types << TypedParams::Types.for({ baz: [1], qux: { a: 2 } }, try: nil)

        types.each do |type|
          expect(type.type).to eq :hash
          expect(type.subtype?).to be false
        end
      end
    end
  end

  describe '.[]' do
    it 'should fetch type by key' do
      type = TypedParams::Types[:string]

      expect(type.type).to eq :string
    end
  end

  describe :boolean do
    let(:type) { TypedParams.types[:boolean] }

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
      t = TypedParams.types.for(true)
      f = TypedParams.types.for(false)

      expect(t.type).to eq :boolean
      expect(f.type).to eq :boolean
    end
  end

  describe :string do
    let(:type) { TypedParams.types[:string] }

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
      t = TypedParams.types.for('foo')

      expect(t.type).to eq :string
    end
  end

  describe :symbol do
    let(:type) { TypedParams.types[:symbol] }

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
      t = TypedParams.types.for(:foo)

      expect(t.type).to eq :symbol
    end
  end

  describe :integer do
    let(:type) { TypedParams.types[:integer] }

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
      t = TypedParams.types.for(1)

      expect(t.type).to eq :integer
    end
  end

  describe :float do
    let(:type) { TypedParams.types[:float] }

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
      t = TypedParams.types.for(1.0)

      expect(t.type).to eq :float
    end
  end

  describe :decimal do
    let(:type) { TypedParams.types[:decimal] }

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
      t = TypedParams.types.for(1.0.to_d)

      expect(t.type).to eq :decimal
    end
  end

  describe :number do
    let(:type) { TypedParams.types[:number] }

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
      integer = TypedParams.types.for(1)
      float   = TypedParams.types.for(1.0)

      expect(integer.type).to_not eq :number
      expect(float.type).to_not eq :number
    end
  end

  describe :array do
    let(:type) { TypedParams.types[:array] }

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
      t = TypedParams.types.for([])

      expect(t.type).to eq :array
    end
  end

  describe :hash do
    let(:type) { TypedParams.types[:hash] }

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
      t = TypedParams.types.for({})

      expect(t.type).to eq :hash
    end
  end

  describe :date do
    let(:type) { TypedParams.types[:date] }

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
      t = TypedParams.types.for(Date.today)

      expect(t.type).to eq :date
    end
  end

  describe :time do
    let(:type) { TypedParams.types[:time] }

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
      t = TypedParams.types.for(Time.now)

      expect(t.type).to eq :time
    end
  end

  describe :nil do
    let(:type) { TypedParams.types[:nil] }

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
      t = TypedParams.types.for(nil)

      expect(t.type).to eq :nil
    end
  end
end