# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Formatters::Rails do
  let :controller do
    Class.new(ActionController::Base) { @controller_name = 'users' }
  end

  let :schema do
    TypedParams::Schema.new(type: :hash) do
      format :rails

      param :first_name, type: :string, optional: true
      param :last_name, type: :string, optional: true
      param :email, type: :string, format: { with: /@/ }
      param :password, type: :string
    end
  end

  let :user do
    {
      first_name: 'Foo',
      last_name: 'Bar',
      email: 'foo@keygen.example',
      password: SecureRandom.hex,
    }
  end

  it 'should format params' do
    params = TypedParams::Parameterizer.new(schema:).call(value: user)

    expect(params.unwrap(controller:)).to eq(user:)
  end

  it 'should format params' do
    params = TypedParams::Parameterizer.new(schema:).call(value: user)

    expect(params.unwrap(formatter: nil)).to eq(user)
  end
end