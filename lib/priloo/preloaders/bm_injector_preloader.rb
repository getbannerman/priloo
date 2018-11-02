# frozen_string_literal: true

module Priloo
    module Preloaders
        # This class implements preloading for Bannerman's custom ActiveRecord injectors
        class BmInjectorPreloader < BasePreloader
            attr_reader :ar_class, :name

            def initialize(ar_class, name)
                super([self.class, ar_class, name])

                @name = name
                @ar_class = ar_class
            end

            def preload(ar_list)
                ids = ar_list.map { |ar| ar.send(primary_key) }
                injector_sql = ar_class.send("#{name}_sql")
                sql_query = Arel.sql <<~SQL
                    #{quote_table_column(ar_class.table_name, primary_key)} AS id,
                    (#{injector_sql}) AS val
                SQL

                fetched_data = ar_class.where(primary_key => ids.uniq).pluck(sql_query).to_h
                ar_list.map { |ar| fetched_data[ar.send(primary_key)] }
            end

            def inject(target, value)
                target._preloadable_target.send(:write_attribute_without_type_cast, name, value)
            end

            def injected?(target)
                target.has_attribute?(name)
            end

            def extract(target)
                target.instance_variable_get(:@attributes).[](name).value
            end

            private

            def quote_identifier(str)
                ar_class.connection.quote_column_name str.to_s
            end

            def quote_table_column(table, column)
                quote_identifier(table) + '.' + quote_identifier(column)
            end

            def primary_key
                @primary_key ||= ar_class.primary_key.to_sym
            end
        end
    end
end
