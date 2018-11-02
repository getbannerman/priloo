# frozen_string_literal: true

require 'tsort'

module Priloo
    class Dependencies
        include TSort

        def initialize(defs)
            @defs = defs
        end

        def tsort_each_node(&block)
            @defs.each_key(&block)
        end

        def tsort_each_child(node, &block)
            @defs.fetch(node).each(&block)
        end

        def self.resolve(defs)
            new(defs).tsort
        end
    end
end
