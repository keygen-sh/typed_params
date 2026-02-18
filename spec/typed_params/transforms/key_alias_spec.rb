# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Transforms::KeyAlias do
  let(:transform) { TypedParams::Transforms::KeyAlias.new(:alias) }

  it 'should rename key to the alias' do
    schema = TypedParams::Schema.new(type: :hash) { param :foo, type: :string, as: :alias }
    params = TypedParams::Parameterizer.new(schema:).call(value: { foo: 'bar' })
    child  = params[:foo]

    transform.call(child)

    expect(child.key).to eq :alias
    expect(child.value).to eq 'bar'
    expect(params[:alias]).to eq child
  end
end
