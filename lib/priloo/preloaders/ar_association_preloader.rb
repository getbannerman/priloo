# frozen_string_literal: true

module Priloo
    module Preloaders
        # This class implements preloading for ActiveRecord associations
        class ArAssociationPreloader < BasePreloader
            attr_reader :ar_class, :name

            def initialize(ar_class, name)
                super([self.class, ar_class, name])

                @name = name
                @ar_class = ar_class
            end

            def injected?(target)
                target.association_cached?(name)
            end

            def extract(target)
                target.send(name)
            end

            def preload(ar_list)
                # Rails does not provide any way to preload an association without immediately
                # storing the result in the instances.
                ActiveRecord::Associations::Preloader.new.preload(ar_list.map(&:_preloadable_target), name)
                ar_list.map(&name)
            end
        end
    end
end
