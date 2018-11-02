# frozen_string_literal: true

require 'singleton'

module Priloo
    module Preloaders
        class CollectionPreloader < BasePreloader
            include Singleton

            def initialize
                super(self.class)
            end

            def multiplicity
                1
            end
        end
    end
end
