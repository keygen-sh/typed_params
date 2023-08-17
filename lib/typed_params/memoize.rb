# frozen_string_literal: true

module TypedParams
  module Memoize
    def self.included(klass) = klass.extend ClassMethods

    module ClassMethods
      cattr_accessor :memoize_queue, default: []

      def memoize
        if memoize_queue.include?(self)
          memoize_queue.clear

          raise RuntimeError, 'memoize cannot be called more than once in succession'
        end

        memoize_queue << self
      end

      private

      def singleton_method_added(method_name)
        while klass = memoize_queue.shift
          raise RuntimeError, "memoize cannot be instrumented more than once for class method #{method_name}" if
            klass.respond_to?(:"unmemoized_#{method_name}")

          method_visibility = case
                              when klass.singleton_class.private_method_defined?(method_name)
                                :private
                              when klass.singleton_class.protected_method_defined?(method_name)
                                :protected
                              when klass.singleton_class.public_method_defined?(method_name)
                                :public
                              end

          klass.singleton_class.send(:alias_method, :"unmemoized_#{method_name}", method_name)
          klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def self.#{method_name}(*args, **kwargs, &block)
              key = args.hash ^ kwargs.hash ^ block.hash

              return @_memoized_#{method_name}_values[key] if
                defined?(@_memoized_#{method_name}_values) && @_memoized_#{method_name}_values.key?(key)

              value     = unmemoized_#{method_name}(*args, **kwargs, &block)
              memo      = @_memoized_#{method_name}_values ||= {}
              memo[key] = value

              value
            end
          RUBY

          klass.singleton_class.send(method_visibility, method_name)
        end

        super
      ensure
        memoize_queue.clear
      end

      def method_added(method_name)
        while klass = memoize_queue.shift
          raise RuntimeError, "memoize cannot be instrumented more than once for instance method #{method_name}" if
            klass.method_defined?(:"unmemoized_#{method_name}")

          method_visibility = case
                              when klass.private_method_defined?(method_name)
                                :private
                              when klass.protected_method_defined?(method_name)
                                :protected
                              when klass.public_method_defined?(method_name)
                                :public
                              end

          klass.alias_method :"unmemoized_#{method_name}", method_name
          klass.class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{method_name}(*args, **kwargs, &block)
              key = args.hash ^ kwargs.hash ^ block.hash

              return @_memoized_#{method_name}_values[key] if
                defined?(@_memoized_#{method_name}_values) && @_memoized_#{method_name}_values.key?(key)

              value     = unmemoized_#{method_name}(*args, **kwargs, &block)
              memo      = @_memoized_#{method_name}_values ||= {}
              memo[key] = value

              value
            end
          RUBY

          klass.send(method_visibility, method_name)
        end

        super
      ensure
        memoize_queue.clear
      end
    end
  end
end
