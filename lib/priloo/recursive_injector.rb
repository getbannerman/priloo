# frozen_string_literal: true

module Priloo
    class RecursiveInjector
        def inject(list, *path)
            inject_deep(list.to_a, canonicalize(path))
            list
        end

        private

        # Little wrapper for 'inject_deep' implementing support for list-of-lists.
        # The input list will be flattened 'multiplicity' times.
        #
        # 1- Flatten the input 'list' such that it can be handled by 'inject_deep'
        # 2- Call 'inject_deep'
        # 3- Un-flatten the preloaded output
        def inject_deep_flat(list, remaining_path, multiplicity)
            return inject_deep(list, remaining_path) if multiplicity == 0

            flat_input = list.flat_map { |v| v.nil? ? [] : v }
            flat_output = inject_deep_flat(flat_input, remaining_path, multiplicity - 1)
            item_index = -1
            list.map { |v| v&.map { flat_output[item_index += 1] } }
        end

        # Extract the necessary preloads & resolve their dependencies.
        #
        # Return:
        # - A new 'resolved_paths' including all recursively resolved dependencies, ordered appropriately.
        # - A two-level list of preloaders[key_index][item_index] (every key/item couple gets its own preloader)
        def resolve_dependencies(list, paths)
            dependencies = {}
            preloaders = {}
            undiscovered = paths.keys

            until undiscovered.empty?
                undiscovered.each do |dep|
                    dependencies[dep] = Set.new
                    preloaders[dep] = list.map { |item| find_preloader(item, dep) }

                    deps = preloaders[dep].uniq(&:merge_key)
                                          .reject { |preloader| preloader.is_a?(Preloaders::NilPreloader) }
                                          .map { |p| canonicalize(p.dependencies) }
                                          .uniq

                    if deps.size > 1
                        # This is a limitation of the current implementation, and at some point we will have to
                        # fix it otherwise it could prevent some things to be done.
                        raise NotImplementedError, 'Different dependencies at the same level are not supported'
                    end

                    deps.each do |d|
                        dependencies[dep] += d.keys
                        paths = paths.deep_merge(d)
                    end
                end

                undiscovered = paths.keys - dependencies.keys
            end

            order = Dependencies.resolve(dependencies)

            resolved_paths = order.map { |key| [key, paths[key]] }.to_h
            preloaders = order.map { |key| preloaders[key] }

            [resolved_paths, preloaders]
        end

        PreloadedValue = Struct.new(:multiplicity, :index, :value)

        def preload_single_key(list, preloaders)
            list.each_with_index
                .group_by { |_item, item_idx| preloaders[item_idx].merge_key }
                .flat_map do |_merge_key, indexed_items|
                    preloader = preloaders[indexed_items.first.last]
                    items = indexed_items.map(&:first)
                    preload_items(preloader, items).each_with_index.map do |value, value_idx|
                        PreloadedValue.new(preloader.multiplicity, indexed_items[value_idx][1], value)
                    end
                end
        end

        def preload_items(preloader, items)
            map_by_group items,
                group_by: ->(x) { preloader.injected?(x) },
                map_to: ->(injected, filtered_items) {
                    next filtered_items.map { |x| preloader.extract(x) } if injected

                    preloader.preload(filtered_items).tap do |preloaded_values|
                        filtered_items.each_with_index do |item, index|
                            preloader.inject(item, preloaded_values[index])
                        end
                    end
                }
        end

        def preload_next_level(preloaded_values, next_level)
            next_values = Array.new(preloaded_values.size)

            preloaded_values.group_by(&:multiplicity)
                            .flat_map do |multiplicity, grouped_preloaded_values|
                values = grouped_preloaded_values.map(&:value)
                results = inject_deep_flat(values, next_level, multiplicity)

                results.each_with_index do |result, result_index|
                    next_values[grouped_preloaded_values[result_index].index] = result
                end
            end

            next_values
        end

        # Preload dependencies at top level and recursively preload next levels
        def inject_deep(list, paths)
            resolved_paths, preloaders = resolve_dependencies(list, paths)

            resolved_paths.each_with_index do |(_key, next_level), key_idx|
                # We preload the key for every item
                preloaded_values = preload_single_key(list, preloaders[key_idx])

                # We recursively preload the next level
                preload_next_level(preloaded_values, next_level)
            end

            list
        end

        def map_by_group(list, group_by: proc { nil }, map_to: proc { |_g, v| v })
            output = Array.new(list.size)

            list.each_with_index.group_by { |item, _idx| group_by[item] }
                .each do |group_key, input_items|
                    input_items_values = input_items.map(&:first)
                    result = map_to[group_key, input_items_values]

                    raise 'Mapper should return same number of rows' unless result.size == input_items.size

                    result.each_with_index do |result_item, result_idx|
                        input_item = input_items[result_idx]
                        input_item_idx = input_item.last

                        output[input_item_idx] = result_item
                    end
                end

            output
        end

        # Find a preloader for any object
        def find_preloader(item, property)
            return Preloaders::NilPreloader.instance if item.nil?

            method = :"#{property}__priloo__"
            preloader = item.send(method) if item.respond_to? method
            preloader ||= Preloaders::CollectionPreloader.instance if property == :__each__ && item.is_a?(Enumerable)
            preloader ||= Preloaders::NavigatingPreloader.new(property)
            raise "Cannot find any preloader for property '#{property}' of #{item}" unless preloader

            preloader
        end

        # Transform a user-friendly path into a canonicalized form more suitable to further processing (idempotent)
        #
        # User-friendly: [:a, :b, {c: [:d], b: :x}]
        # Canonicalized: {:a=>{}, :b=>{:x=>{}}, :c=>{:d=>{}}}
        def canonicalize(path)
            case path
            when Array then path.reduce({}) { |a, p| a.merge(canonicalize(p)) }
            when Hash then path.map { |k, v| [k.to_sym, canonicalize(v)] }.to_h
            else { path.to_sym => {} }
            end
        end
    end
end
