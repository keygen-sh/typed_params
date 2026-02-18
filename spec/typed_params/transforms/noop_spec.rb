# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Transforms::Noop do
  let(:transform) { TypedParams::Transforms::Noop.new }

  it 'should delete param' do
    schema = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, noop: true }
    params = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'bar' })
    child  = params[:foo]

    transform.call(child)

    expect(params[:foo]).to be nil
  end
end
