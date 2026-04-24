# frozen_string_literal: true

# Copyright (c) Steven Hoffman
# All rights reserved.

require 'unary_plus'

require 'active_record'
require 'active_support'

::ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
::ActiveRecord::Base.logger = ::Logger.new($stdout)

::ActiveRecord::Schema.define do
  create_table :employees, force: true do |t|
    t.string :username
    t.text :website_bio
    t.string :email
    t.string :aliases
  end

  create_table :posts, force: true do |t|
    t.text :body
  end
end

::RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.disable_monkey_patching!
  config.warnings = true
  # config.profile_examples = 10
  config.order = :random

  ::Kernel.srand config.seed
end
