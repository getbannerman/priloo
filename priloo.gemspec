# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'lib/priloo/version')

Gem::Specification.new do |gem|
    gem.name = 'priloo'
    gem.version       = Priloo::VERSION
    gem.licenses      = ['MIT']
    gem.authors       = ['Frederic Terrazzoni']
    gem.email         = ['frederic.terrazzoni@gmail.com']
    gem.description   = 'A generalized Rails-like preloader'
    gem.summary       = gem.description
    gem.homepage      = 'https://github.com/getbannerman/priloo'

    gem.files         = `git ls-files lib`.split($INPUT_RECORD_SEPARATOR)
    gem.executables   = []
    gem.test_files    = []
    gem.require_paths = ['lib']

    gem.add_development_dependency 'bm-typed', '~> 0.1'
    gem.add_development_dependency 'coveralls', '~> 0.8'
    gem.add_development_dependency 'pry', '~> 0'
    gem.add_development_dependency 'rspec', '~> 3'
    gem.add_development_dependency 'rubocop', '0.59.2'
    gem.add_development_dependency 'sqlite3', '~> 1.3'

    gem.add_dependency 'activerecord', '~> 5.2.1'
    gem.add_dependency 'decors', '~> 0.3'
end
