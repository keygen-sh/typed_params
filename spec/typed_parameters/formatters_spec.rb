# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Formatters do
  describe '.register' do
    after { TypedParameters::Formatters.unregister(:test) }

    it 'should register format' do
      format = TypedParameters::Formatters.register(:test,
        transform: -> k, v { [k, v] },
      )

      expect(TypedParameters::Formatters.formats[:test]).to eq format
    end

    it 'should not register a duplicate format' do
      format = TypedParameters::Formatters.register(:test,
        transform: -> k, v { [k, v] },
      )

      expect { TypedParameters::Formatters.register(:test, transform: -> k, v { [k, v] }) }
        .to raise_error ArgumentError
    end
  end

  describe '.unregister' do
    it 'should unregister format' do
      TypedParameters::Formatters.register(:test, transform: -> k, v { [k, v] },)
      TypedParameters::Formatters.unregister(:test)

      expect(TypedParameters::Formatters.formats[:test]).to be_nil
    end
  end

  describe '.[]' do
    it 'should fetch format by key' do
      format = TypedParameters::Formatters[:jsonapi]

      expect(format.format).to eq :jsonapi
    end
  end
end