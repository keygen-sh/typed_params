# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Validations::Exclusion do
  let(:validation) { TypedParameters::Validations::Exclusion.new(options) }
  let(:options)    { nil }

  context 'with in: option' do
    let(:options) {{ in: %w[a b c] }}

    it 'should succeed' do
      expect { validation.call('d') }.to_not raise_error
    end

    it 'should fail' do
      expect { validation.call('a') }.to raise_error TypedParameters::ValidationError
    end
  end
end