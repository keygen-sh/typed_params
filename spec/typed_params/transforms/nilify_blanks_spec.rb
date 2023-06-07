# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Transforms::NilifyBlanks do
  let(:transform) { TypedParams::Transforms::NilifyBlanks.new }

  [
    string: '',
    array: [],
    hash: {},
  ].each do |key, value|
    it "should transform blank #{key} to nil" do
      k, v = transform.call(key, value)

      expect(k).to eq key
      expect(v).to be nil
    end
  end

  [
    string: 'foo',
    array: [:foo],
    hash: { foo: :bar },
  ].each do |key, value|
    it "should not transform present #{key} to nil" do
      k, v = transform.call(key, value)

      expect(k).to eq key
      expect(v).to be value
    end
  end
end