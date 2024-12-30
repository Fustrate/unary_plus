# frozen_string_literal: true

# Copyright (c) Steven Hoffman
# All rights reserved.

module UnaryPlus
  module Concerns
    module CleanAttributes
      extend ::ActiveSupport::Concern

      STRING_TYPES = %i[string text citext].freeze

      # Collapse multiple spaces, remove leading/trailing whitespace, and remove carriage returns
      def self.strip(text)
        return text.map { strip(it) } if text.is_a?(::Array)

        return if text.blank?

        text.strip.gsub(/ {2,}/, ' ').gsub(/^[ \t]+|[ \t]+$/, '').gsub(/\r\n?/, "\n").gsub(/\n{3,}/, "\n\n")
      end

      def self.polymorphic_type_columns(klass)
        klass.reflect_on_all_associations.filter_map { "#{it.name}_type" if it.options[:polymorphic] }
      end

      def self.string_columns(klass)
        # There's no reason to clean polymorphic type columns
        type_columns = polymorphic_type_columns(klass)

        klass.columns.filter_map { it.name if self::STRING_TYPES.include?(it.type) && !type_columns.include?(it.name) }
      end

      def self.clean_record(record)
        string_columns(record.class).each do |attribute|
          next unless record[attribute]

          record[attribute] = strip record[attribute]
        end
      end

      included do
        before_validation { ::UnaryPlus::Concerns::CleanAttributes.clean_record(self) }
      end
    end
  end
end
