# frozen_string_literal: true

module Priloo
    module Preloaders
        class NavigatingPreloader < BasePreloader
            attr_reader :name

            def initialize(name)
                super([self.class, name])

                @name = name
            end

            def preload(instances)
                instances.map { |inst| extract(inst) }
            end

            def extract(target)
                return target[name] if target.is_a?(Hash)
                return target.send(name) if target.respond_to?(name)
            end
        end
    end
end
