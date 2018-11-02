# frozen_string_literal: true

module Priloo
    module Preloaders
        class NilPreloader < BasePreloader
            include Singleton

            def initialize
                super(self)
            end

            def preload(instances)
                Array.new(instances.size)
            end
        end
    end
end
