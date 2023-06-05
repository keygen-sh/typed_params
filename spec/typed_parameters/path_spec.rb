# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Path do
  let(:path)   { TypedParameters::Path.new(:foo, :bar_baz, 42, :qux, casing:) }
  let(:casing) { TypedParameters.config.path_transform }

  it 'should support JSON pointer paths' do
    expect(path.to_json_pointer).to eq '/foo/bar_baz/42/qux'
  end

  it 'should support dot notation paths' do
    expect(path.to_dot_notation).to eq 'foo.bar_baz.42.qux'
  end

  context 'with no path transform' do
    it 'should not transform path' do
      expect(path.to_s).to eq 'foo.bar_baz[42].qux'
    end
  end

  context 'with :underscore path transform' do
    let(:casing) { :underscore }

    it 'should transform path' do
      expect(path.to_s).to eq 'foo.bar_baz[42].qux'
    end
  end

  context 'with :camel path transform' do
    let(:casing) { :camel }

    it 'should transform path' do
      expect(path.to_s).to eq 'Foo.BarBaz[42].Qux'
    end
  end

  context 'with :lower_camel path transform' do
    let(:casing) { :lower_camel }

    it 'should transform path' do
      expect(path.to_s).to eq 'foo.barBaz[42].qux'
    end
  end

  context 'with :dash path transform' do
    let(:casing) { :dash }

    it 'should transform path' do
      expect(path.to_s).to eq 'foo.bar-baz[42].qux'
    end
  end

  context 'with config path transform' do
    before { TypedParameters.config.path_transform = :lower_camel }

    it 'should transform path' do
      expect(path.to_s).to eq 'foo.barBaz[42].qux'
    end
  end
end