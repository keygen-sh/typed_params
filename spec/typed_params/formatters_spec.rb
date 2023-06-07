# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Formatters do
  describe '.register' do
    after { TypedParams::Formatters.unregister(:test) }

    it 'should register format' do
      format = TypedParams::Formatters.register(:test,
        transform: -> k, v { [k, v] },
      )

      expect(TypedParams::Formatters.formats[:test]).to eq format
    end

    it 'should not register a duplicate format' do
      format = TypedParams::Formatters.register(:test,
        transform: -> k, v { [k, v] },
      )

      expect { TypedParams::Formatters.register(:test, transform: -> k, v { [k, v] }) }
        .to raise_error ArgumentError
    end
  end

  describe '.unregister' do
    it 'should unregister format' do
      TypedParams::Formatters.register(:test, transform: -> k, v { [k, v] },)
      TypedParams::Formatters.unregister(:test)

      expect(TypedParams::Formatters.formats[:test]).to be_nil
    end
  end

  describe '.[]' do
    it 'should fetch format by key' do
      format = TypedParams::Formatters[:jsonapi]

      expect(format.format).to eq :jsonapi
    end
  end
end