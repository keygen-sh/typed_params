# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Schema do
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

  %i[
    array
    hash
  ].each do |type|
    it "should allow block for type: #{type.inspect}" do
      expect { TypedParams::Schema.new(type:) {} }.to_not raise_error
    end
  end

  %i[
    boolean
    string
    integer
    float
    decimal
    number
    symbol
    date
    time
    nil
  ].each do |type|
    it "should not allow block for type: #{type.inspect}" do
      expect { TypedParams::Schema.new(type:) {} }.to raise_error ArgumentError
    end
  end

  context 'with :array type' do
    it 'should raise when defining param' do
      expect { TypedParams::Schema.new(type: :array) { param :foo, type: :string } }.to raise_error NotImplementedError
    end

    it 'should not raise when defining items' do
      expect { TypedParams::Schema.new(type: :array) { items type: :string } }.to_not raise_error
    end

    it 'should not raise when defining an item' do
      expect { TypedParams::Schema.new(type: :array) { item type: :string } }.to_not raise_error
    end

    it 'should raise on endless index conflict' do
      expect { TypedParams::Schema.new(type: :array) { items type: :string; item type: :string } }
        .to raise_error ArgumentError
    end

    it 'should raise on sparse index conflict' do
      expect { TypedParams::Schema.new(type: :array) { item type: :string; items type: :string } }
        .to raise_error ArgumentError
    end
  end

  context 'with :hash type' do
    it 'should not raise when defining param' do
      expect { TypedParams::Schema.new(type: :hash) { param :foo, type: :string } }.to_not raise_error
    end

    it 'should not raise when defining items' do
      expect { TypedParams::Schema.new(type: :hash) { items type: :string } }.to raise_error NotImplementedError
    end

    it 'should not raise when defining an item' do
      expect { TypedParams::Schema.new(type: :hash) { item type: :string } }.to raise_error NotImplementedError
    end
  end

  %i[
    in
  ].each do |option|
    it "should not raise on valid :inclusion option: #{option.inspect}" do
      expect { TypedParams::Schema.new(type: :string, inclusion: { option => %w[foo] }) }.to_not raise_error
    end
  end

  it 'should raise on invalid :inclusion options' do
    expect { TypedParams::Schema.new(type: :string, inclusion: { invalid: %w[foo] }) }
      .to raise_error ArgumentError
  end

  it 'should raise on missing :inclusion options' do
    expect { TypedParams::Schema.new(type: :string, inclusion: {}) }
      .to raise_error ArgumentError
  end

  %i[
    in
  ].each do |option|
    it "should not raise on valid :exclusion option: #{option.inspect}" do
      expect { TypedParams::Schema.new(type: :string, exclusion: { option => %w[bar] }) }.to_not raise_error
    end
  end

  it 'should raise on invalid :exclusion options' do
    expect { TypedParams::Schema.new(type: :string, exclusion: { invalid: %w[bar] }) }
      .to raise_error ArgumentError
  end

  it 'should raise on missing :exclusion options' do
    expect { TypedParams::Schema.new(type: :string, exclusion: {}) }
      .to raise_error ArgumentError
  end

  %i[
    with
    without
  ].each do |option|
    it "should not raise on valid :format option: #{option.inspect}" do
      expect { TypedParams::Schema.new(type: :string, format: { option => /baz/ }) }.to_not raise_error
    end
  end

  it 'should raise on multiple :format options' do
    expect { TypedParams::Schema.new(type: :string, format: { with: /baz/, without: /qux/ }) }
      .to raise_error ArgumentError
  end

  it 'should raise on invalid :format options' do
    expect { TypedParams::Schema.new(type: :string, format: { invalid: /baz/ }) }
      .to raise_error ArgumentError
  end

  it 'should raise on missing :format options' do
    expect { TypedParams::Schema.new(type: :string, format: {}) }
      .to raise_error ArgumentError
  end

  {
    minimum: 1,
    maximum: 1,
    within: 1..3,
    in: [1, 2, 3],
    is: 1,
  }.each do |option, length|
    it "should not raise on valid :length option: #{option.inspect}" do
      expect { TypedParams::Schema.new(type: :string, length: { option => length }) }.to_not raise_error
    end
  end

  it 'should not raise on multiple :length options' do
    expect { TypedParams::Schema.new(type: :string, length: { minimum: 1, maximum: 42 }) }
      .to_not raise_error
  end

  it 'should raise on multiple :length options' do
    expect { TypedParams::Schema.new(type: :string, length: { in: 1..3, maximum: 42 }) }
      .to raise_error ArgumentError
  end

  it 'should raise on invalid :length options' do
    expect { TypedParams::Schema.new(type: :string, length: { invalid: /bar/ }) }
      .to raise_error ArgumentError
  end

  it 'should raise on missing :length options' do
    expect { TypedParams::Schema.new(type: :string, length: {}) }
      .to raise_error ArgumentError
  end

  describe '#source' do
    [
      :params,
      :query,
      nil,
    ].each do |source|
      it "should not raise on valid :source: #{source.inspect}" do
        expect { TypedParams::Schema.new(type: :string, source:) }.to_not raise_error
      end
    end

    it 'should raise on invalid :source' do
      expect { TypedParams::Schema.new(type: :string, source: :foo) }
        .to raise_error ArgumentError
    end
  end

  describe '#path' do
    it 'should have correct path' do
      grandchild = schema.children[:foo]
                         .children[:bar]
                         .children[0]
                         .children[:baz]

      expect(grandchild.path.to_json_pointer).to eq '/foo/bar/0/baz'
    end
  end

  describe '#keys' do
    it 'should have correct array keys' do
      grandchild = schema.children[:foo]
                         .children[:bar]

      expect(grandchild.keys).to eq [0]
    end

    it 'should have correct hash keys' do
      grandchild = schema.children[:foo]

      expect(grandchild.keys).to eq %i[bar]
    end
  end

  describe '#format' do
    it 'should not raise for root node' do
      expect { TypedParams::Schema.new { format :jsonapi } }
        .to_not raise_error
    end

    it 'should raise for child node' do
      expect { TypedParams::Schema.new { param(:key, type: :hash) { format :jsonapi } } }
        .to raise_error NotImplementedError
    end
  end

  describe '#with' do
    let :schema do
      TypedParams::Schema.new type: :hash do
        with optional: true, if: -> { true } do
          param :foo, type: :string
          param :bar, type: :string
          param :baz, type: :hash do
            param :qux, type: :string
          end
        end
      end
    end

    it 'should pass options to children' do
      children = schema.children.values

      expect(children.all?(&:optional?)).to be true
      expect(children.all?(&:if?)).to be true
    end

    it 'should not pass options to grandchildren' do
      grandchildren = schema.children[:baz].children.values

      expect(grandchildren.all?(&:optional?)).to be false
      expect(grandchildren.all?(&:if?)).to be false
    end

    context 'with overrides' do
      let :schema do
        TypedParams::Schema.new type: :hash do
          with optional: true, if: -> { true } do
            param :foo, type: :string, optional: false
            param :bar, type: :string
            param :baz, type: :string
          end
        end
      end

      it 'should support per-param overrides' do
        children = schema.children.values

        expect(children[0].optional?).to be false
        expect(children[0].if?).to be true

        expect(children[1].optional?).to be true
        expect(children[1].if?).to be true

        expect(children[2].optional?).to be true
        expect(children[2].if?).to be true
      end
    end
  end
end
