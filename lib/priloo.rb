# frozen_string_literal: true

require 'active_support'

require 'priloo/version'
require 'priloo/recursive_injector'
require 'priloo/preloadable'
require 'priloo/dependencies'
require 'priloo/preloaders/base_preloader'
require 'priloo/preloaders/ar_association_preloader'
require 'priloo/preloaders/bm_injector_preloader'
require 'priloo/preloaders/collection_preloader'
require 'priloo/preloaders/generic_preloader'
require 'priloo/preloaders/navigating_preloader'
require 'priloo/preloaders/nil_preloader'

ActiveSupport.on_load(:active_record) do
    require 'priloo/active_record_support'
end

module Priloo
    def self.preload(*params)
        RecursiveInjector.new.inject(*params)
    end
end

module Enumerable
    def priload(*args)
        Priloo.preload(self, args)
    end
end
