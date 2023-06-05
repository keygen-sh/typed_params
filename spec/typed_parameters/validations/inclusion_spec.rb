# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Validations::Inclusion do
  let(:validation) { TypedParameters::Validations::Inclusion.new(options) }
  let(:options)    { nil }

  context 'with in: option' do
    context 'with range' do
      let(:options) {{ in: 0..9 }}

      it 'should succeed' do
        expect { validation.call(0) }.to_not raise_error
      end

      it 'should fail' do
        expect { validation.call(10) }.to raise_error TypedParameters::ValidationError
      end
    end

    context 'with array' do
      let(:options) {{ in: %w[a b c] }}

      it 'should succeed' do
        expect { validation.call('a') }.to_not raise_error
      end

      it 'should fail' do
        expect { validation.call('d') }.to raise_error TypedParameters::ValidationError
      end
    end
  end
end