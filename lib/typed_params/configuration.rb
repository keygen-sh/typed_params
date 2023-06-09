# frozen_string_literal: true

module TypedParams
  class Configuration
    include ActiveSupport::Configurable

    ##
    # ignore_nil_optionals defines how nil optionals are handled.
    # When enabled, optional params that are nil will be dropped
    # given the schema does not allow_nil. Essentially, they
    # will be treated as if they weren't provided.
    config_accessor(:ignore_nil_optionals) { false }

    ##
    # path_transform defines the casing for parameter paths.
    #
    # One of:
    #
    #   - :underscore
    #   - :camel
    #   - :lower_camel
    #   - :dash
    #   - nil
    #
    config_accessor(:path_transform) { nil }

    ##
    # key_transform defines the casing for parameter keys.
    #
    # One of:
    #
    #   - :underscore
    #   - :camel
    #   - :lower_camel
    #   - :dash
    #   - nil
    #
    config_accessor(:key_transform) { nil }
  end
end
