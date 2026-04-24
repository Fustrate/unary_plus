# frozen_string_literal: true

# Copyright (c) Steven Hoffman
# All rights reserved.

require 'spec_helper'

class Employee < ::ActiveRecord::Base
  include ::UnaryPlus::Concerns::CleanAttributes

  serialize :aliases

  after_initialize do |employee|
    employee.aliases = [] if employee.aliases.nil?
  end
end

::RSpec.describe ::UnaryPlus::Concerns::CleanAttributes do
  it 'nilifies blank strings' do
    employee = ::Employee.new(username: "\n\t ", email: ' ', website_bio: "\t\t\t")

    employee.validate

    expect(employee).to have_attributes(username: nil, email: nil, website_bio: nil)
  end

  it 'strips non-blank strings' do
    employee = ::Employee.new(
      username: "  strip this text\n",
      email: "  strip this text\n",
      website_bio: "  strip this text\n"
    )

    employee.validate

    expect(employee)
      .to have_attributes(username: 'strip this text', email: 'strip this text', website_bio: 'strip this text')
  end

  it 'strips an array of strings' do
    employee = ::Employee.new(username: "\n\t ", email: ' ', website_bio: "\t\t\t", aliases: [' dave', 'd dawg '])

    employee.validate

    expect(employee).to have_attributes(username: nil, email: nil, website_bio: nil, aliases: ['dave', 'd dawg'])
  end

  it 'removes trailing spaces on each line' do
    employee = ::Employee.new(
      username: "hello \nworld\t\n!",
      email: "hello \nworld\t\n!",
      website_bio: "hello \nworld\t\n!"
    )

    employee.validate

    expect(employee)
      .to have_attributes(username: "hello\nworld\n!", email: "hello\nworld\n!", website_bio: "hello\nworld\n!")
  end

  it 'normalizes CRLF and CR to LF' do
    employee = ::Employee.new(
      username: "hello\r\nworld\r!",
      email: "hello\r\n world\r!",
      website_bio: "hello\r \nworld\r!"
    )

    employee.validate

    expect(employee)
      .to have_attributes(username: "hello\nworld\n!", email: "hello\nworld\n!", website_bio: "hello\nworld\n!")
  end

  it 'removes excessive newlines' do
    employee = ::Employee.new(
      username: "hello\n\n\n\n\n\n\nworld!",
      email: "hello \n\n\n\n\n\n\nworld!",
      website_bio: "hello\n\n\n \n\n\n\nworld!"
    )

    employee.validate

    expect(employee)
      .to have_attributes(username: "hello\n\nworld!", email: "hello\n\nworld!", website_bio: "hello\n\nworld!")
  end

  it 'collapses multiple consecutive spaces into one' do
    employee = ::Employee.new(username: 'hello   world', email: 'a  b  c', website_bio: 'x  y')

    employee.validate

    expect(employee).to have_attributes(username: 'hello world', email: 'a b c', website_bio: 'x y')
  end

  describe '.strip' do
    it 'returns nil for nil input' do
      expect(described_class.strip(nil)).to be_nil
    end

    it 'returns nil for a blank string' do
      expect(described_class.strip('   ')).to be_nil
    end

    it 'processes each element when given an array' do
      expect(described_class.strip(['  hello  ', '  world  '])).to eq %w[hello world]
    end

    it 'returns nil elements for blank array entries' do
      expect(described_class.strip(['', '  ', nil])).to eq [nil, nil, nil]
    end
  end
end
