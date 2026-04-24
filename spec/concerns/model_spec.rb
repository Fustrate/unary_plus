# frozen_string_literal: true

# Copyright (c) Steven Hoffman
# All rights reserved.

require 'spec_helper'

module UnaryPlusTest
  class Article < ::ActiveRecord::Base
    include ::UnaryPlus::Concerns::Model
  end
end

::RSpec.describe ::UnaryPlus::Concerns::Model do
  describe '.human_name' do
    before { ::UnaryPlusTest::Article.instance_variable_set(:@human_name, nil) }

    it 'defaults to the underscored class name without the namespace' do
      expect(::UnaryPlusTest::Article.human_name).to eq 'article'
    end

    it 'can be set to a custom name' do
      ::UnaryPlusTest::Article.human_name('my article')

      expect(::UnaryPlusTest::Article.human_name).to eq 'my article'
    end

    it 'persists the custom name across calls' do
      ::UnaryPlusTest::Article.human_name('my article')

      2.times { ::UnaryPlusTest::Article.human_name }

      expect(::UnaryPlusTest::Article.human_name).to eq 'my article'
    end

    it 'strips the namespace from the default name' do
      expect(::UnaryPlusTest::Article.human_name).not_to include('unary_plus_test')
    end
  end
end
