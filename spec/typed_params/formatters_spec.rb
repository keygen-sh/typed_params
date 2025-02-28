# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Formatters do
  after { TypedParams::Formatters.unregister(:test) }

  describe '.register' do
    it 'should register format' do
      format = TypedParams::Formatters.register(:test,
        transform: -> params { params },
      )

      expect(TypedParams::Formatters.formats[:test]).to eq format
    end

    it 'should not register a duplicate format' do
      format = TypedParams::Formatters.register(:test,
        transform: -> params { params },
      )

      expect { TypedParams::Formatters.register(:test, transform: -> params { params }) }
        .to raise_error ArgumentError
    end
  end

  describe '.unregister' do
    it 'should unregister format' do
      TypedParams::Formatters.register(:test, transform: -> params { params })
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

  it 'should use format' do
    TypedParams::Formatters.register(:test,
      transform: -> params { params.deep_transform_keys { _1.to_s.camelize(:lower).to_sym } },
    )

    schema = TypedParams::Schema.new(type: :hash) do
      format :test

      param :foo_bar, type: :string
    end

    params = TypedParams::Parameterizer.new(schema:).call(
      value: { foo_bar: 'baz' },
    )

    expect(params.unwrap).to eq(fooBar: 'baz')
  end
end
