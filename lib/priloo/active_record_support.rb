# frozen_string_literal: true

require 'active_record'

module Priloo
    module ActiveRecordSupport
        def method_missing(method, *)
            generate_priloo_method(method) || super
        end

        def respond_to_missing?(method, _)
            !generate_priloo_method(method).nil? || super
        end

        PRILOO_SUFFIX_REGEX = /__priloo__\z/

        def generate_priloo_method(method)
            index = method =~ PRILOO_SUFFIX_REGEX
            return unless index

            property = method.slice(0, index).to_sym

            preloader =
                case
                when self.class.reflect_on_association(property)
                    Preloaders::ArAssociationPreloader.new(self.class, property)
                when self.class.respond_to?("#{property}_sql")
                    Preloaders::BmInjectorPreloader.new(self.class, property)
                end

            self.class.define_method(method) { preloader }

            preloader
        end

        def _preloadable_target
            self
        end
    end

    ActiveRecord::Base.include(ActiveRecordSupport)
end
