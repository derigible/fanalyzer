# frozen_string_literal: true

require 'active_support/core_ext/object/blank'

module Queries
  module Concerns
    module Date
      private

      def date_filters(models)
        models, after_date = after_date_filter(models)
        before_date_filter(models, after_date)
      end

      def before_date_filter(models, compare = nil)
        use = prompt.ask(
          'Enter a date to find all before that date with format ' \
          '`Month/Day/Year (mm/dd/yyyy)` (leave blank to see all):'
        )
        return models if use.blank?

        before_date = ::Date.strptime(use, '%m/%d/%Y')

        if compare && compare > before_date
          puts 'Cannot have a use a date that occurred before the date ' \
          "#{compare.iso8601}as that is the beginning of the range already " \
          'defined.'

          before_date_filter(models, compare)
        end

        models.where { date > before_date }
      end

      def after_date_filter(models)
        use = prompt.ask(
          'Enter a date to find all after that date with format ' \
          '`Month/Day/Year (mm/dd/yyyy)` (leave blank to see all):'
        )
        return models if use.blank?

        after_date = ::Date.strptime(use, '%m/%d/%Y')

        [models.where { date > after_date }, after_date]
      end
    end
  end
end
