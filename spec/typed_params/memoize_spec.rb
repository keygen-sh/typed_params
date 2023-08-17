# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParams::Memoize do
  describe '.memoize' do
    it 'memoizes' do
      a = Class.new {
        include TypedParams::Memoize

        memoize
        def without_args = SecureRandom.hex
      }.new

      expect(a).to receive(:without_args).twice.and_call_original
      expect(a).to receive(:unmemoized_without_args).once

      a.without_args
      a.without_args
    end

    it 'memoizes args' do
      a = Class.new {
        include TypedParams::Memoize

        memoize
        def with_args(n) = SecureRandom.hex(n)
      }.new

      expect(a).to receive(:with_args).twice.and_call_original
      expect(a).to receive(:unmemoized_with_args).once

      a.with_args(64)
      a.with_args(64)
    end

    it 'memoizes kwargs' do
      a = Class.new {
        include TypedParams::Memoize

        memoize
        def with_kwargs(n:) = SecureRandom.hex(n)
      }.new

      expect(a).to receive(:with_kwargs).twice.and_call_original
      expect(a).to receive(:unmemoized_with_kwargs).once

      a.with_kwargs(n: 64)
      a.with_kwargs(n: 64)
    end

    it 'memoizes block' do
      a = Class.new {
        include TypedParams::Memoize

        memoize
        def with_block(&b) = SecureRandom.hex(b.call)
      }.new

      expect(a).to receive(:with_block).twice.and_call_original
      expect(a).to receive(:unmemoized_with_block).once

      a.with_block &b = -> { 64 }
      a.with_block &b
    end

    it 'should raise on repeat instance method memoize' do
      expect {
        Class.new {
          include TypedParams::Memoize

          memoize
          memoize
          def call = nil
        }
      }.to raise_error RuntimeError
    end

    it 'should raise on repeat instance method def' do
      expect {
        Class.new {
          include TypedParams::Memoize

          memoize
          def call = nil

          memoize
          def call = nil
        }
      }.to raise_error RuntimeError
    end

    it 'should raise on repeat class method memoize' do
      expect {
        Class.new {
          include TypedParams::Memoize

          memoize
          memoize
          def self.call = nil
        }
      }.to raise_error RuntimeError
    end

    it 'should raise on repeat class method def' do
      expect {
        Class.new {
          include TypedParams::Memoize

          memoize
          def self.call = nil

          memoize
          def self.call = nil
        }
      }.to raise_error RuntimeError
    end

    context 'with public instance method' do
      subject {
        Class.new {
          include TypedParams::Memoize

          memoize
          def without_args = SecureRandom.hex

          memoize
          def with_args(i) = SecureRandom.hex(i)
        }
      }

      it 'memoizes with correct visibility' do
        expect(subject.public_method_defined?(:without_args)).to be true
        expect(subject.public_method_defined?(:with_args)).to be true
      end

      context 'with same instance' do
        it 'memoizes no args' do
          a = subject.new

          expect(a).to receive(:without_args).and_call_original
          expect(a).to receive(:unmemoized_without_args).and_call_original
          x = a.without_args

          expect(a).to receive(:without_args).and_call_original
          expect(a).not_to receive(:unmemoized_without_args)
          y = a.without_args

          expect(x).to eq y
        end

        it 'memoizes same args' do
          a = subject.new

          expect(a).to receive(:with_args).and_call_original
          expect(a).to receive(:unmemoized_with_args).and_call_original
          x = a.with_args(16)

          expect(a).to receive(:with_args).and_call_original
          expect(a).not_to receive(:unmemoized_with_args)
          y = a.with_args(16)

          expect(x).to eq y
        end

        it 'memoizes diff args' do
          a = subject.new

          expect(a).to receive(:with_args).and_call_original
          expect(a).to receive(:unmemoized_with_args).and_call_original
          x = a.with_args(16)

          expect(a).to receive(:with_args).and_call_original
          expect(a).to receive(:unmemoized_with_args).and_call_original
          y = a.with_args(32)

          expect(x).to_not eq y
        end
      end

      context 'with diff instance' do
        it 'memoizes no args' do
          a = subject.new
          b = subject.new

          expect(a).to receive(:without_args).and_call_original
          expect(a).to receive(:unmemoized_without_args).and_call_original
          x = a.without_args

          expect(b).to receive(:without_args).and_call_original
          expect(b).to receive(:unmemoized_without_args)
          y = b.without_args

          expect(x).to_not eq y
        end

        it 'memoizes same args' do
          a = subject.new
          b = subject.new

          expect(a).to receive(:with_args).and_call_original
          expect(a).to receive(:unmemoized_with_args).and_call_original
          x = a.with_args(16)

          expect(b).to receive(:with_args).and_call_original
          expect(b).to receive(:unmemoized_with_args).and_call_original
          y = b.with_args(16)

          expect(x).to_not eq y
        end

        it 'memoizes diff args' do
          a = subject.new
          b = subject.new

          expect(a).to receive(:with_args).and_call_original
          expect(a).to receive(:unmemoized_with_args).and_call_original
          x = a.with_args(16)

          expect(b).to receive(:with_args).and_call_original
          expect(b).to receive(:unmemoized_with_args).and_call_original
          y = b.with_args(32)

          expect(x).to_not eq y
        end
      end
    end

    context 'with private instance method' do
      subject {
        Class.new {
          include TypedParams::Memoize

          def without_args   = priv_without_args
          def with_args(...) = priv_with_args(...)

          private

          memoize
          def priv_without_args = SecureRandom.hex

          memoize
          def priv_with_args(i) = SecureRandom.hex(i)
        }
      }

      it 'memoizes with correct visibility' do
        expect(subject.private_method_defined?(:priv_without_args)).to be true
        expect(subject.private_method_defined?(:priv_with_args)).to be true
      end

      context 'with same instance' do
        it 'memoizes no args' do
          a = subject.new

          expect(a).to receive(:priv_without_args).and_call_original
          expect(a).to receive(:unmemoized_priv_without_args).and_call_original
          x = a.without_args

          expect(a).to receive(:priv_without_args).and_call_original
          expect(a).not_to receive(:unmemoized_priv_without_args)
          y = a.without_args

          expect(x).to eq y
        end

        it 'memoizes same args' do
          a = subject.new

          expect(a).to receive(:priv_with_args).and_call_original
          expect(a).to receive(:unmemoized_priv_with_args).and_call_original
          x = a.with_args(16)

          expect(a).to receive(:priv_with_args).and_call_original
          expect(a).not_to receive(:unmemoized_priv_with_args)
          y = a.with_args(16)

          expect(x).to eq y
        end

        it 'memoizes diff args' do
          a = subject.new

          expect(a).to receive(:priv_with_args).and_call_original
          expect(a).to receive(:unmemoized_priv_with_args).and_call_original
          x = a.with_args(16)

          expect(a).to receive(:priv_with_args).and_call_original
          expect(a).to receive(:unmemoized_priv_with_args).and_call_original
          y = a.with_args(32)

          expect(x).to_not eq y
        end
      end

      context 'with diff instance' do
        it 'memoizes no args' do
          a = subject.new
          b = subject.new

          expect(a).to receive(:priv_without_args).and_call_original
          expect(a).to receive(:unmemoized_priv_without_args).and_call_original
          x = a.without_args

          expect(b).to receive(:priv_without_args).and_call_original
          expect(b).to receive(:unmemoized_priv_without_args)
          y = b.without_args

          expect(x).to_not eq y
        end

        it 'memoizes same args' do
          a = subject.new
          b = subject.new

          expect(a).to receive(:priv_with_args).and_call_original
          expect(a).to receive(:unmemoized_priv_with_args).and_call_original
          x = a.with_args(16)

          expect(b).to receive(:priv_with_args).and_call_original
          expect(b).to receive(:unmemoized_priv_with_args).and_call_original
          y = b.with_args(16)

          expect(x).to_not eq y
        end

        it 'memoizes diff args' do
          a = subject.new
          b = subject.new

          expect(a).to receive(:priv_with_args).and_call_original
          expect(a).to receive(:unmemoized_priv_with_args).and_call_original
          x = a.with_args(16)

          expect(b).to receive(:priv_with_args).and_call_original
          expect(b).to receive(:unmemoized_priv_with_args).and_call_original
          y = b.with_args(32)

          expect(x).to_not eq y
        end
      end
    end

    context 'with public class method' do
      subject {
        Class.new {
          include TypedParams::Memoize

          memoize
          def self.without_args = SecureRandom.hex

          memoize
          def self.with_args(i) = SecureRandom.hex(i)
        }
      }

      it 'memoizes with correct visibility' do
        expect(subject.singleton_class.public_method_defined?(:without_args)).to be true
        expect(subject.singleton_class.public_method_defined?(:with_args)).to be true
      end

      it 'memoizes no args' do
        expect(subject).to receive(:without_args).and_call_original
        expect(subject).to receive(:unmemoized_without_args).and_call_original
        x = subject.without_args

        expect(subject).to receive(:without_args).and_call_original
        expect(subject).not_to receive(:unmemoized_without_args)
        y = subject.without_args

        expect(x).to eq y
      end

      it 'memoizes same args' do
        expect(subject).to receive(:with_args).and_call_original
        expect(subject).to receive(:unmemoized_with_args).and_call_original
        x = subject.with_args(16)

        expect(subject).to receive(:with_args).and_call_original
        expect(subject).not_to receive(:unmemoized_with_args)
        y = subject.with_args(16)

        expect(x).to eq y
      end

      it 'memoizes diff args' do
        expect(subject).to receive(:with_args).and_call_original
        expect(subject).to receive(:unmemoized_with_args).and_call_original
        x = subject.with_args(16)

        expect(subject).to receive(:with_args).and_call_original
        expect(subject).to receive(:unmemoized_with_args).and_call_original
        y = subject.with_args(32)

        expect(x).to_not eq y
      end
    end

    context 'with private class method' do
      subject {
        Class.new {
          include TypedParams::Memoize

          def self.without_args   = priv_without_args
          def self.with_args(...) = priv_with_args(...)

          memoize
          private_class_method def self.priv_without_args = SecureRandom.hex

          memoize
          private_class_method def self.priv_with_args(i) = SecureRandom.hex(i)
        }
      }

      it 'memoizes with correct visibility' do
        expect(subject.singleton_class.private_method_defined?(:priv_without_args)).to be true
        expect(subject.singleton_class.private_method_defined?(:priv_with_args)).to be true
      end

      it 'memoizes no args' do
        expect(subject).to receive(:priv_without_args).and_call_original
        expect(subject).to receive(:unmemoized_priv_without_args).and_call_original
        x = subject.without_args

        expect(subject).to receive(:priv_without_args).and_call_original
        expect(subject).not_to receive(:unmemoized_priv_without_args)
        y = subject.without_args

        expect(x).to eq y
      end

      it 'memoizes same args' do
        expect(subject).to receive(:priv_with_args).and_call_original
        expect(subject).to receive(:unmemoized_priv_with_args).and_call_original
        x = subject.with_args(16)

        expect(subject).to receive(:priv_with_args).and_call_original
        expect(subject).not_to receive(:unmemoized_priv_with_args)
        y = subject.with_args(16)

        expect(x).to eq y
      end

      it 'memoizes diff args' do
        expect(subject).to receive(:priv_with_args).and_call_original
        expect(subject).to receive(:unmemoized_priv_with_args).and_call_original
        x = subject.with_args(16)

        expect(subject).to receive(:priv_with_args).and_call_original
        expect(subject).to receive(:unmemoized_priv_with_args).and_call_original
        y = subject.with_args(32)

        expect(x).to_not eq y
      end
    end
  end
end
