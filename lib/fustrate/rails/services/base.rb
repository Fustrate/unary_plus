# frozen_string_literal: true

module Fustrate
  module Rails
    module Services
      class Base
        # Lets us use `t` and `l` helpers.
        include ActionView::Helpers::TranslationHelper

        attr_reader :current_user, :params

        def initialize(current_user = nil, params = {})
          @current_user = current_user

          @params = process_params(params)
        end

        protected

        def service(service_class)
          service_class.new(current_user, params)
        end

        def authorize(action, resource)
          Authority.enforce(action, resource, current_user)
        end

        def transaction(&block)
          ActiveRecord::Base.transaction(&block)
        end

        def process_params(params)
          return params if params.is_a? ActionController::Parameters

          ActionController::Parameters.new(params)
        end

        class LoadPage < self
          DEFAULT_ORDER = nil
          DEFAULT_INCLUDES = nil
          RESULTS_PER_PAGE = 25

          def call(page: nil, includes: nil, scope: nil, order: nil)
            (scope || default_scope)
              .reorder(order || default_order)
              .paginate(
                page: (page || params[:page]),
                per_page: self.class::RESULTS_PER_PAGE
              )
              .includes(includes || self.class::DEFAULT_INCLUDES)
          end

          protected

          def default_scope
            raise '#default_scope not defined'
          end

          def default_order
            if self.class::DEFAULT_ORDER.is_a? Proc
              return self.class::DEFAULT_ORDER.call
            end

            self.class::DEFAULT_ORDER
          end
        end
      end
    end
  end
end