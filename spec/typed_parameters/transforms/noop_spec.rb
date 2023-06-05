# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Transforms::Noop do
  let(:transform) { TypedParameters::Transforms::Noop.new }

  it 'should be noop' do
    k, v = transform.call('foo', 'bar')

    expect(k).to be nil
    expect(v).to be nil
  end
end