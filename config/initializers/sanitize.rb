# frozen_string_literal: true

# Copyright (c) Steven Hoffman
# All rights reserved.

require 'sanitize'

class Sanitize
  class CSS
    def properties(css)
      tree = ::Crass.parse_properties(
        css,
        preserve_comments: @config[:allow_comments],
        preserve_hacks: @config[:allow_hacks]
      )

      tree!(tree)

      CSSTreeStringifier.new.stringify(tree)
    end
  end

  class CSSTreeStringifier
    # Options:
    #
    #   * **:exclude_comments** - When `true`, comments will be excluded.
    def initialize(**options)
      @options = options
    end

    # Converts a node or array of nodes from an inline style attribute into a CSS string based on
    # their original tokenized input.
    def stringify(nodes)
      @string = +''
      @last = {}

      nodes.each do |node|
        next if node.nil?

        append_stringified_node(node)

        @last = node
      end

      @string.strip
    end

    protected

    def append_stringified_node(node)
      return append_comment_node(node) if node[:node] == :comment
      return append_whitespace_node if node[:node] == :whitespace

      if node.key?(:raw)
        @string << node[:raw]
      elsif node.key?(:tokens)
        @string << self.class.new(**@options).stringify(node[:tokens])
      end
    end

    def append_comment_node(node)
      @string << node[:raw] unless exclude_comments?
    end

    def append_whitespace_node
      # No consecutive whitespace or whitespace after property names
      @string << ' ' if allow_whitespace?
    end

    def allow_whitespace? = @last[:node] != :ident && !@string.end_with?(' ')

    def exclude_comments? = @options[:exclude_comments]
  end

  SELF_CLOSING = %w[br td img hr input].freeze

  class << self
    def clean_nodes(node)
      # Replace non-root empty nodes with a blank space
      return node.replace(' ') if empty_element?(node)

      # Replace root empty nodes with a newline
      if node.text? && !node.parent&.parent && node.text.blank?
        # Replacing a newline with a newline causes an infinite loop
        return node.text == "\n" ? node : node.replace("\n")
      end

      clean_style_attribute(node)
      clean_attributes(node)
      clean_whitespace(node)
    end

    def clean_page_breaks(node)
      return unless node.element?

      if node.content.match?(/↡/)
        node.content = '↡'
        node['class'] = 'pagebreak'
        node.remove_attribute 'style'
      elsif node['class']
        node.remove_attribute 'class'
      end
    end

    protected

    # Remove useless padding and text-align attributes
    def clean_style_attribute(node)
      return unless node['style']

      style = node['style']
        .gsub(/padding: 0(?:px|rem|in|em|);/, '')
        .gsub(/text-align: (?:start|justify|left);/, '')
        .strip

      if style.present?
        node['style'] = style
      else
        node.remove_attribute 'style'
      end
    end

    # Remove empty attributes from a node, e.g. alt=""
    def clean_attributes(node)
      return unless node.element?

      node.attributes.each do |key, value|
        node.remove_attribute(key) if value.text.empty?
      end
    end

    def clean_whitespace(node)
      return clean_element_whitespace(node) unless node.text?

      node.content = node.content.gsub(/[[:space:]]+/, ' ')
    end

    def clean_element_whitespace(node)
      return unless node.name.casecmp('p').zero?

      clean_paragraph_tag(node.children.first, true)
      clean_paragraph_tag(node.children.last, false)
    end

    def clean_paragraph_tag(node, is_first)
      return unless node&.text?

      return node.content = '' if node.text.blank?

      # Remove all leading whitespace and replace all space-like chars with a single space
      node.content = node.content
        .gsub(is_first ? /\A[[:space:]]+/ : /[[:space:]]+\z/, '')
        .gsub(/[[:space:]]+/, ' ')
    end

    def empty_element?(node) = node.element? && !self_closing?(node) && !content?(node)

    def content?(node) = text?(node) || (node.element? && node.children.any? { content_or_self_closing?(it) })

    def content_or_self_closing?(node) = self_closing?(node) || text?(node) || content?(node)

    def self_closing?(node) = self::SELF_CLOSING.include?(node.name.downcase)

    def text?(node) = node.text? && node.text.present?
  end
end
