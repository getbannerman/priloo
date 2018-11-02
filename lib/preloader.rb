# frozen_string_literal: true

module Preloader
    module_function

    def preload(*params)
        ::Preloader::RecursiveInjector.new.inject(*params)
    end

    class PreloadFailure < BannermanException; end
end
