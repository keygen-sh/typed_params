# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Validations::Length do
  let(:validation) { TypedParameters::Validations::Length.new(options) }
  let(:options)    { nil }

  context 'with minimum: option' do
    let(:options) {{ minimum: 5 }}

    it 'should succeed' do
      expect { validation.call('foobar') }.to_not raise_error
    end

    it 'should fail' do
      expect { validation.call('foo') }.to raise_error TypedParameters::ValidationError
    end
  end

  context 'with maximum: option' do
    let(:options) {{ maximum: 5 }}

    it 'should succeed' do
      expect { validation.call('foo') }.to_not raise_error
    end

    it 'should fail' do
      expect { validation.call('foobarbaz') }.to raise_error TypedParameters::ValidationError
    end
  end

  context 'with within: option' do
    context 'with range' do
      let(:options) {{ within: 1..3 }}

      it 'should succeed' do
        expect { validation.call('foo') }.to_not raise_error
      end

      it 'should fail' do
        expect { validation.call('foobar') }.to raise_error TypedParameters::ValidationError
      end
    end

    context 'with array' do
      let(:options) {{ within: [0, 2, 4, 6] }}

      it 'should succeed' do
        expect { validation.call('foobar') }.to_not raise_error
      end

      it 'should fail' do
        expect { validation.call('foo') }.to raise_error TypedParameters::ValidationError
      end
    end
  end

  context 'with in: option' do
    context 'with range' do
      let(:options) {{ in: 1...6 }}

      it 'should succeed' do
        expect { validation.call('foo') }.to_not raise_error
      end

      it 'should fail' do
        expect { validation.call('foobar') }.to raise_error TypedParameters::ValidationError
      end
    end

    context 'with array' do
      let(:options) {{ in: [0, 2, 4, 6] }}

      it 'should succeed' do
        expect { validation.call('foobar') }.to_not raise_error
      end

      it 'should fail' do
        expect { validation.call('foo') }.to raise_error TypedParameters::ValidationError
      end
    end
  end

  context 'with is: option' do
    let(:options) {{ is: 42 }}

    it 'should succeed' do
      expect { validation.call('a'*42) }.to_not raise_error
    end

    it 'should fail' do
      expect { validation.call('a'*7) }.to raise_error TypedParameters::ValidationError
    end
  end
end