# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../dummy/config/environment', __FILE__)

require 'rspec/rails'
require 'typed_params'

RSpec.configure do |config|
  config.expect_with(:rspec) { _1.syntax = :expect }
  config.disable_monkey_patching!

  config.before :each do
    @ignore_nil_optionals_was = TypedParams.config.ignore_nil_optionals
    @path_transform_was       = TypedParams.config.path_transform
    @key_transform_was        = TypedParams.config.key_transform

    # FIXME(ezekg) Add a config.reset! method in test envs?
    TypedParams.config.ignore_nil_optionals = false
    TypedParams.config.path_transform       = nil
    TypedParams.config.key_transform        = nil
  end

  config.after :each do
    TypedParams.config.ignore_nil_optionals = @ignore_nil_optionals_was
    TypedParams.config.path_transform       = @path_transform_was
    TypedParams.config.key_transform        = @key_transform_was
  end
end
