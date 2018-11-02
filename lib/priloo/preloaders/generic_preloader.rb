# frozen_string_literal: true

module Priloo
    module Preloaders
        class GenericPreloader < BasePreloader
            attr_reader :name, :block, :dependencies

            PRIVATE_STORE_NAME = :@preloader_private_store

            def initialize(name, dependencies: [], &block)
                super(self)
                @name = name
                @dependencies = dependencies
                @block = block
            end

            def preload(instances)
                block[instances]
            end

            def injected?(target)
                fetch_store(target)&.key?(name) || false
            end

            def extract(target)
                fetch_store(target).fetch(name)
            end

            def inject(target, value)
                fetch_or_create_store(target)[name] = value
            end

            private

            def fetch_store(target)
                target._preloadable_target.instance_variable_get(PRIVATE_STORE_NAME)
            end

            def fetch_or_create_store(target)
                obj = target._preloadable_target
                return fetch_store(target) if obj.instance_variable_defined?(PRIVATE_STORE_NAME)

                store = {}
                obj.instance_variable_set(PRIVATE_STORE_NAME, store)
                store
            end
        end
    end
end
