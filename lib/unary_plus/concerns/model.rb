# frozen_string_literal: true

# Copyright (c) Steven Hoffman
# All rights reserved.

module UnaryPlus
  module Concerns
    module Model
      extend ::ActiveSupport::Concern

      module ClassMethods
        # Allow models to define a more reasonable name, usually used to remove a module/namespace.
        def human_name(new_name = nil)
          @human_name = new_name.to_s if new_name

          @human_name ||= to_s.underscore.gsub(%r{\A.*/}, '')
        end

        def build_from_params(permitted_params, **attributes)
          key = attributes.delete(:params_key)

          new(**attributes) { it.assign_params(permitted_params, key:) }
        end
      end

      included do
        self.abstract_class = true
        self.inheritance_column = :_disabled

        # Assign strong parameters based on the class name - just a convenience method for services.
        def assign_params(permitted_params, key: nil)
          if key == false
            assign_attributes ::Current.params.permit(permitted_params)
          else
            assign_attributes ::Current.params.require(key || default_param_key).permit(permitted_params)
          end
        end

        # Define a different Editable record to log edits on
        def log_edits_on = self

        def default_param_key = ::ActiveModel::Naming.param_key(self.class)
      end
    end
  end
end
