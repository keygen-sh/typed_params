# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypedParameters::Configuration do
  subject { TypedParameters::Configuration.new }

  describe '#ignore_nil_optionals=' do
    it('should respond') { expect(subject).to respond_to :ignore_nil_optionals= }
  end

  describe '#ignore_nil_optionals' do
    it('should respond') { expect(subject).to respond_to :ignore_nil_optionals }
  end

  describe '#path_transform=' do
    it('should respond') { expect(subject).to respond_to :path_transform= }
  end

  describe '#path_transform' do
    it('should respond') { expect(subject).to respond_to :path_transform }
  end

  describe '#key_transform=' do
    it('should respond') { expect(subject).to respond_to :key_transform= }
  end

  describe '#key_transform' do
    it('should respond') { expect(subject).to respond_to :key_transform }
  end
end