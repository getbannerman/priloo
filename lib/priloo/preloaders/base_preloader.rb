# frozen_string_literal: true

module Priloo
    module Preloaders
        class BasePreloader
            attr_reader :merge_key

            def initialize(merge_key)
                @merge_key = merge_key
            end

            def multiplicity
                0
            end

            def injected?(_target)
                false
            end

            def preload(instances)
                instances
            end

            def inject(_target, _value); end

            def dependencies
                []
            end
        end
    end
end
