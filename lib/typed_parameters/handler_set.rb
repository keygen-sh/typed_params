# frozen_string_literal: true

require 'typed_parameters/namespaced_set'

module TypedParameters
  class HandlerSet
    attr_reader :deferred,
                :params,
                :query

    def initialize
      @deferred = []
      @params   = NamespacedSet.new
      @query    = NamespacedSet.new
    end

    def deferred? = @deferred.any?
  end
end
