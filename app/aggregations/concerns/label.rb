# frozen_string_literal: true

require 'active_support/core_ext/object/blank'

module Aggregations
  module Concerns
    module Label
      private

      def label_filters(models)
        if prompt.yes?('Filter by label?')
          filter!(models)
        else
          models
        end
      end

      def filter!(models, additional = false)
        use = prompt.select(
          'Choose label filtering strategy to apply:',
          enum: '.',
          per_page: 7
        ) do |menu|
          if additional
            menu.choice(
              'Exclude transactions without label', :exclude_without_labels
            )
          else
            menu.choice 'Exclude transactions with labels', :exclude_labels
            menu.choice 'Include transactions with labels', :include_labels
          end
          menu.choice 'Cancel', :cancel
        end
        return models if use == :cancel

        send(use, models)
      end
    end
  end
end
