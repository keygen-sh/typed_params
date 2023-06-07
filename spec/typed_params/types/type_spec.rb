# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Types::Type do
  let :type do
    TypedParams::Types::Type.new(
      type: :hash,
      name: :object,
      accepts_block: true,
      scalar: false,
      coerce: -> v { v.respond_to?(:to_h) ? v.to_h : {} },
      match: -> v { v.is_a?(Hash) },
      abstract: false,
      archetype: nil,
    )
  end

  describe '#match?' do
    it 'should match self' do
      expect(type.match?(type)).to be true
    end

    it 'should match value' do
      expect(type.match?({})).to be true
    end

    it 'should not match value' do
      expect(type.match?(1)).to be false
    end
  end

  describe '#mismatch?' do
    it 'should not match self' do
      expect(type.mismatch?(type)).to be false
    end

    it 'should not match value' do
      expect(type.mismatch?({})).to be false
    end

    it 'should match value' do
      expect(type.mismatch?(1)).to be true
    end
  end

  describe '#humanize' do
    it 'should return humanized name' do
      expect(type.humanize).to eq 'object'
    end

    context 'with subtype' do
      let :subtype do
        TypedParams::Types::Type.new(
          type: :shallow_hash,
          name: :shallow,
          accepts_block: true,
          scalar: false,
          coerce: -> v { v.respond_to?(:to_h) ? v.to_h : {} },
          match: -> v { v.is_a?(Hash) && v.values.none? { _1.is_a?(Array) || _1.is_a?(Hash) } },
          abstract: false,
          archetype: type,
        )
      end

      it 'should return humanized name' do
        expect(subtype.humanize).to eq 'shallow object'
      end
    end
  end
end