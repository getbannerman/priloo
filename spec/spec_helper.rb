# frozen_string_literal: true

require 'coveralls'
Coveralls.wear! do
    add_filter 'spec'
end

ENV['RAILS_ENV'] = 'test'

require 'priloo'
require 'typed'
require 'active_record'

ActiveRecord::Base.configurations['test'] = {
    adapter: 'sqlite3',
    database: ':memory:'
}

ActiveRecord::Base.establish_connection :test

ActiveRecord::Schema.define do
    create_table :posts, force: true do |t|
        t.column :user_id, :integer, null: false
    end

    create_table :users, force: true
end

class Post < ActiveRecord::Base
    belongs_to :user

    def self.answer_to_life_sql
        '21 + 21'
    end
end

class User < ActiveRecord::Base
    has_many :posts
end

module IsExpectedBlock
    def is_expected_block
        expect { subject }
    end
end

RSpec.configure do |config|
    config.include IsExpectedBlock
end
