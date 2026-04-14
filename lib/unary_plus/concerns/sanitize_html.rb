# frozen_string_literal: true

# Copyright (c) Steven Hoffman
# All rights reserved.

require 'sanitize'

module UnaryPlus
  module Concerns
    module SanitizeHtml
      extend ::ActiveSupport::Concern

      def self.sanitize(html, config)
        return if html.nil?

        smart_strip ::Sanitize.fragment(normalize(html), config)
      end

      # Remove non-breaking & ideographic spaces before sanitizing, and un-fancy quotes.
      def self.normalize(html) = html.tr('‘’“”', %q(''"")).gsub(/(?:[\u00A0\u3000]|&nbsp;) ?/, ' ')

      # There shouldn't be whitespace or newlines at the beginning or end of the text
      def self.smart_strip(html) = html.gsub(/\A(?:[[:space:]]|<br>)+|(?:[[:space:]]|<br>)+\z/, '')

      module ClassMethods
        def sanitize_html(*attributes, config)
          before_validation do
            attributes.flatten.each do |attribute|
              next unless self[attribute]

              self[attribute] = ::UnaryPlus::Concerns::SanitizeHtml.sanitize(self[attribute], config)
            end
          end
        end
      end
    end
  end
end
