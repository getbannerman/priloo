# Priloo

[![Build Status](https://api.travis-ci.com/getbannerman/priloo.svg?branch=master)](https://travis-ci.com/getbannerman/priloo)
[![Coverage Status](https://coveralls.io/repos/github/getbannerman/priloo/badge.svg)](https://coveralls.io/github/getbannerman/priloo)
[![Gem](https://img.shields.io/gem/v/priloo.svg)](https://rubygems.org/gems/priloo)
[![Downloads](https://img.shields.io/gem/dt/priloo.svg)](https://rubygems.org/gems/priloo)

## Description

`Priloo` is a generalized preloader. It is inspired from `ActiveRecord#preload(...)`, but it works for any object implementing
its preloading protocol.

## Property tree

Priloo accepts a collection and a tree of properties. The syntax is very similar to `ActiveRecord#preload`. The only difference is the special property `__each__`, used to visit items of a collection.

```ruby
# ActiveRecord
collection.preload(user: { posts: :attachment })

# Priloo
collection.priload(user: { posts: { __each__: :attachment } })
```

## ActiveRecord integration

`Priloo` integrates natively with `ActiveRecord`'s preloader. The advantage if that you can traverse both AR and non-AR object, or have add custom preloadable properties to your ARs.

## BABL integration

[BABL](https://github.com/getbannerman/babl/) can be configured to use `Priloo` by default.

```ruby
::Babl.configure do |config|
    config.preloader = Priloo
end
```

BABL extracts the property tree from the template, and passes it to `Priloo`. No more N+1!

## Preloading protocol

In order to have a preloadable property `foo`, an object must respond to the method `foo__priloo__` and return a preloader.

All objects having the same preloader are loaded together using `preloader.preload([...])`.

If a property is not preloadable, `Priloo` fallbacks to calling the method (or access the property, for `Hash`). If the method doesn't exist, the error is ignored.

## Custom preloadable properties

### PreloadDependencies()

`PreloadDependencies` can be used to ensure properties are preloaded before the property is computed.

```ruby
class Post
end

class User
    include Priloo::Preloadable

    has_many :posts

    # This decorator tells Priloo to load all posts, before
    # calling the method.
    PreloadDependencies(:posts)
    def number_of_likes
        posts.map(&:likes)
    end
end

# Usage
users.priload(:number_of_likes).each(&:number_of_likes) # No N+1, all posts are loaded at once.
```

### PreloadBatch()

`PreloadBatch` is more general and makes it possible to write
a completely custom preloading logic.

```ruby
class Post
end

class User
    include Priloo::Preloadable

    has_many :posts

    # This decorator tells Priloo how to preload 'number_of_likes' for a collection of users.
    # For convenience, it also creates a similarly-named instance method.
    PreloadBatch()
    def self.number_of_likes(users)
        users.map { ... }
    end
end

# Usage
users.priload(:number_of_likes).each(&:number_of_likes) # No N+1
```

## Install

```ruby
gem 'priloo'
```

## Limitations

This gem is a PoC and has certain limitations which makes it unsuitable for production, unless you know what you're doing.

- The current implementation assumes that all objects at the same level have the same dependencies. If that's not the case, an exception is raised.

- This gem is badly tested. Some parts are not even tested at all.

- Error handling sucks. We should definitely adopt a "fail-fast" approach, instead of "ignore errors".

- ActiveRecord integration relies on Rails internals, and the way we're calling native ActiveRecord::Preloader isn't safe (see https://github.com/rails/rails/issues/32140).

## License

Copyright (c) 2018 [Bannerman](https://www.bannerman.com/), [Frederic Terrazzoni](https://github.com/fterrazzoni)

Licensed under the [MIT license](https://opensource.org/licenses/MIT).
