# frozen_string_literal: true

require 'decors'

module Priloo
    module Preloadable
        def self.included(base)
            base.extend ClassMethods
        end

        # This method in only called in Preloaders::GenericPreloader
        #
        # Its purpose is to make sure instance variables are injected in the right instance,
        # if it is behind a proxy (for instance, a SimpleDelegator). We cannot be 100% sure
        # that the proxy will forward Object#instance_variable_set() properly
        def _preloadable_target
            self
        end

        def priloo_clearall
            return unless instance_variable_defined?(Preloaders::GenericPreloader::PRIVATE_STORE_NAME)

            remove_instance_variable(Preloaders::GenericPreloader::PRIVATE_STORE_NAME)
        end

        class PreloadDependencies < ::Decors::DecoratorBase
            def initialize(*)
                super

                @preloader = Preloaders::GenericPreloader.new(
                    decorated_method_name,
                    dependencies: [*decorator_args, **decorator_kwargs]
                ) { |list| list.map { |inst| undecorated_method.bind(inst._preloadable_target).call } }

                decorated_class.declare_preloader(decorated_method_name, preloader)
            end

            def call(instance, *)
                return preloader.extract(instance) if preloader.injected?(instance)

                preloader.preload([instance].bm_preload(*decorator_args, **decorator_kwargs)).first
            end

            private

            attr_reader :preloader
        end

        class PreloadBatch < ::Decors::DecoratorBase
            def initialize(*)
                super

                clazz = ObjectSpace.each_object(decorated_class).first

                preloader = Preloaders::GenericPreloader.new(
                    decorated_method_name,
                    dependencies: [*decorator_args, **decorator_kwargs]
                ) { |list| undecorated_method.bind(clazz).call(list) }

                clazz.declare_preloader(decorated_method_name, preloader)

                clazz.send(:define_method, decorated_method_name) do
                    return preloader.extract(self) if preloader.injected?(self)

                    preloader.preload([self]).first
                end
            end
        end

        module ClassMethods
            def preload_define(name, *dependencies, &block)
                preloader = Preloaders::GenericPreloader.new(name, dependencies: dependencies, &block)
                declare_preloader(name, preloader)

                define_method(name) do
                    return preloader.extract(self) if preloader.injected?(self)

                    preloader.preload([self]).first
                end
            end

            def preload_delegate(*names, to:, allow_nil: false, prefix: false)
                names.each do |name|
                    prefixed_name = prefix ? :"#{to}_#{name}" : name

                    preload_define prefixed_name, to => name do |items|
                        items.map do |item|
                            through = item.send(to)
                            raise "Cannot delegate #{name} to #{to} because Nil is not allowed" if !allow_nil && through.nil?

                            through&.send(name)
                        end
                    end
                end
            end

            def preload_ar(name, primary_key, ar_class_name, foreign_key)
                preload_define name do |items|
                    ids = items.map { |item| item.send(primary_key) }.compact.uniq
                    data = ar_class_name.constantize.where(foreign_key => ids).map { |c| [c.send(foreign_key), c] }.to_h
                    items.map { |item| data[item.send(primary_key)] }
                end
            end

            def preload_many_ar(name, primary_keys, ar_class_name, foreign_key)
                preload_define name do |items|
                    ids = items.map { |item| item.send(primary_keys) }.flatten.compact.uniq
                    data = ar_class_name.constantize.where(foreign_key => ids).map { |c| [c.send(foreign_key), c] }.to_h
                    items.map { |item| item.send(primary_keys)&.map { |pk| data[pk] } }
                end
            end

            extend Decors::DecoratorDefinition

            define_mixin_decorator :PreloadDependencies, PreloadDependencies
            define_mixin_decorator :PreloadBatch, PreloadBatch

            def declare_preloader(name, preloader)
                define_method(:"#{name}__priloo__") { preloader }
            end
        end
    end
end
