# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date_and_time/calculations'

module Queries
  module Concerns
    module Date
      private

      def date_filters(models)
        if prompt.yes?('Filter by date?')
          use = prompt.select(
            'Choose date filtering strategy:', enum: '.'
          ) do |menu|
            menu.choice 'Last 7 days', :past_7_days
            menu.choice 'Last 30 days', :past_30_days
            menu.choice 'Enter previous number days', :past_custom_days
            menu.choice 'This month', :this_month
            menu.choice 'This quarter', :this_quarter
            menu.choice 'Year to date', :year_to_date
            menu.choice 'Custom', :custom
          end
          send(use, models)
        else
          models
        end
      end

      def past_7_days(models)
        past_n_days(models, 7)
      end

      def past_30_days(models)
        past_n_days(models, 30)
      end

      def past_custom_days(models)
        num = prompt.ask('Enter number of days previous:') do |q|
          q.convert(:int)
        end
        past_n_days(models, num)
      rescue TTY::Prompt::ConversionError
        puts 'Invalid number, please enter a number.'
        past_custom_days(models)
      end

      def this_quarter(models)
        d = ::Date.today
        apply_after_date_filter(models, d.beginning_of_quarter).first
      end

      def this_month(models)
        d = ::Date.today
        apply_after_date_filter(models, d.beginning_of_month).first
      end

      def year_to_date(models)
        d = ::Date.today
        apply_after_date_filter(models, d.beginning_of_year).first
      end

      def past_n_days(models, num)
        apply_after_date_filter(models, num.days.ago).first
      end

      def custom(models)
        models, after_date = after_date_filter(models)
        before_date_filter(models, after_date)
      end

      def before_date_filter(models, compare = nil)
        use = prompt.ask(
          'Before date - format ' \
          '`Month/Day/Year (mm/dd/yyyy)` (leave blank to see all):'
        )
        return models if use.blank?

        before_date = ::Date.strptime(use, '%m/%d/%Y')

        if compare && compare > before_date
          puts 'Cannot use a date that occurred before the date ' \
          "#{compare.iso8601} as that is the beginning of the range already " \
          'defined.'

          before_date_filter(models, compare)
        end

        models.where { date < before_date }
      end

      def after_date_filter(models)
        use = prompt.ask(
          'After date - format ' \
          '`Month/Day/Year (mm/dd/yyyy)` (leave blank to see all):'
        )
        return models if use.blank?

        after_date = ::Date.strptime(use, '%m/%d/%Y')

        apply_after_date_filter(models, after_date)
      end

      def apply_after_date_filter(models, after_date)
        [models.where { date > after_date }, after_date]
      end
    end
  end
end
