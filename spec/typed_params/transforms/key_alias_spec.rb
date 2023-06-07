# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Transforms::KeyAlias do
  let(:transform) { TypedParams::Transforms::KeyAlias.new(:alias) }

  it 'should rename key to the alias' do
    k, v = transform.call(:foo, :bar)

    expect(k).to eq :alias
    expect(v).to be :bar
  end
end