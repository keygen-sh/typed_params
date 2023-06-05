# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Validations::Format do
  let(:validation) { TypedParameters::Validations::Format.new(options) }
  let(:options)    { nil }

  context 'with without: option' do
    let(:options) {{ without: /foo/ }}

    it 'should succeed' do
      expect { validation.call('bar') }.to_not raise_error
    end

    it 'should fail' do
      expect { validation.call('foo') }.to raise_error TypedParameters::ValidationError
    end
  end

  context 'with with: option' do
    let(:options) {{ with: /foo/ }}

    it 'should succeed' do
      expect { validation.call('foo') }.to_not raise_error
    end

    it 'should fail' do
      expect { validation.call('bar') }.to raise_error TypedParameters::ValidationError
    end
  end
end