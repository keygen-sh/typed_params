# frozen_string_literal: true

require 'typed_params/namespaced_set'

module TypedParams
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
