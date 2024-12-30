# frozen_string_literal: true

# Copyright (c) Steven Hoffman
# All rights reserved.

module UnaryPlus
  module Services
    module LogEdit
      IGNORE_COLUMNS = %w[id created_at updated_at].freeze
      RENAME_COLUMNS = {}.freeze

      attr_reader :subject, :force, :note, :user

      def call(subject, force: false, note: nil, user: nil)
        # Make sure any before_validation callbacks are run
        subject.validate

        @subject = subject
        @force = force
        @note = note
        @user = user || ::Current.user

        process_changes

        self.class::RENAME_COLUMNS.each do |from, to|
          changes[to] = changes.delete(from) if changes[from]
        end

        record_edit
      end

      protected

      def changes
        @changes ||= subject.changes.except(*self.class::IGNORE_COLUMNS)
      end

      def record_edit
        clean_changes!

        return if changes.empty? && !force

        subject.log_edits_on.edits.new(
          user:,
          note:,
          reason: ::Current.params[:reason],
          pretty_changes: changes,
          raw_changes:
        )
      end

      # Get rid of changes from nil to '' and whatnot
      def clean_changes! = changes.delete_if { |_, values| values.all?(&:blank?) || values.first == values.last }

      def raw_changes = subject.changes

      def process_changes
        process_timestamps(:datetime, '%-m/%-d/%y %-I:%M %p')
        process_timestamps(:date, '%-m/%-d/%y')
        process_timestamps(:time, '%-I:%M %p')

        process_boolean_columns
        process_relations
      end

      def process_timestamps(type, time_format)
        columns_of_type(type).each do |column_name|
          changes[column_name].map! { it&.strftime(time_format) }
        end
      end

      def process_boolean_columns
        columns_of_type(:boolean).each do |column_name|
          changes[column_name] = changes[column_name][1] ? %w[No Yes] : %w[Yes No]
        end
      end

      def columns_of_type(type) = Array(columns[type]).select { changes[it] }

      def process_relations
        subject.class.reflect_on_all_associations.each do |relation|
          if relation.options[:polymorphic]
            process_polymorphic_relation(relation.name)
          elsif relation.is_a?(::ActiveRecord::Reflection::BelongsToReflection)
            process_belongs_to_relation(relation.name)
          end
        end
      end

      def process_polymorphic_relation(name)
        return unless changes["#{name}_id"] || changes["#{name}_type"]

        changes.delete("#{name}_id")
        changes.delete("#{name}_type")

        changes[name] = [find_old_polymorphic_record(name), subject.__send__(name)&.to_s]
      end

      def find_old_polymorphic_record(name)
        # The type, and in rare cases the ID, may not have actually changed
        old_id = subject.__send__(:"#{name}_id_in_database")
        old_type = subject.__send__(:"#{name}_type_in_database").presence

        ::Object.const_get(old_type).find(old_id)&.to_s if old_type
      end

      def unignored_columns = subject.class.columns.reject { self.class::IGNORE_COLUMNS.include?(it.name) }

      def columns
        @columns ||= unignored_columns
          .group_by { it.sql_type_metadata.type }
          .transform_values { |cols| cols.map { it.name.to_sym } }
      end

      def process_belongs_to_relation(name)
        return unless changes["#{name}_id"]

        new_value = subject.__send__(name)

        old_value_id = changes.delete("#{name}_id").first

        # If we're removing the value, new_value.class will be nil, so we need to use reflection.
        changes[name] = [
          (subject.class.reflect_on_association(name).klass.find(old_value_id)&.to_s if old_value_id),
          new_value&.to_s
        ]
      end
    end
  end
end
