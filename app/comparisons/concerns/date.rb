# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date_and_time/calculations'
require_relative './date/compare_by_number'
require_relative './date/compare_month_by_month'
require_relative './date/compare_quarter_by_quarter'
require_relative './date/compare_year_by_year'
require_relative './date/compare_year_to_date'
require_relative './date/compare_month_to_date'

module Comparisons
  module Concerns
    module Date
      include Comparisons::Concerns::Date::CompareByNumber
      include Comparisons::Concerns::Date::CompareMonthByMonth
      include Comparisons::Concerns::Date::CompareQuarterByQuarter
      include Comparisons::Concerns::Date::CompareYearByYear
      include Comparisons::Concerns::Date::CompareMonthToDate
      include Comparisons::Concerns::Date::CompareYearToDate

      private

      def date_comparisons(models)
        num_periods_between = ask_num_periods_between
        num_comparisons = ask_number_comparisons
        period = comparison_period
        comps = []
        (0..num_comparisons - 1).each do |i|
          comps << do_compare(models, num_periods_between, period, i)
        end
        comps
      end

      def do_compare(models, num_periods_between, period, iteration)
        if period.is_a? Numeric
          compare_by_number(models, num_periods_between, period, iteration)
        else
          send(
            "compare_#{period}".to_sym,
            models, num_periods_between, iteration
          )
        end
      end

      def comparison_period
        use = prompt.select(
          'Choose comparison period type:', enum: '.', per_page: 8
        ) do |menu|
          menu.choice '7 days', :days_7
          menu.choice '30 days', :days_30
          menu.choice 'Custom number days', :days_custom
          menu.choice 'Month ', :month_by_month
          menu.choice 'Quarter', :quarter_by_quarter
          menu.choice 'Year', :year_by_year
          menu.choice 'Month to Date', :month_to_date
          menu.choice 'Year to Date', :year_to_date
        end
        return use if %i[
          month_by_month
          quarter_by_quarter
          year_by_year
          month_to_date
          year_to_date
        ].include?(use)

        send(use)
      end

      def ask_number_comparisons
        num_comparisons = prompt.ask(
          'How many comparisons? ' \
          '(Numbers less than 1 and blank will default to 1)'
        ) do |q|
          q.convert :int
        end
        num_comparisons = 1 if num_comparisons.nil? || num_comparisons < 1
        num_comparisons
      rescue TTY::Prompt::ConversionError
        puts 'Must be a number.'
        ask_number_comparisons
      end

      def ask_num_periods_between
        periods = prompt.ask(
          'Enter number of periods between to compare. For example, compare ' \
          'previous 7 days with 7 day period ending 21 days ago (3 periods). ' \
          '(Numbers less than 1 and blank will be 1)'
        ) do |q|
          q.convert :int
        end
        periods = 1 if periods.nil? || periods < 1
        periods
      rescue TTY::Prompt::ConversionError
        puts 'Must be a number.'
        ask_num_periods_between
      end

      def days_7
        7
      end

      def days_30
        30
      end

      def days_custom
        num = prompt.ask(
          'Enter number of days in period ' \
          '(Numbers less than 1 or blank will be 1):'
        ) do |q|
          q.convert(:int)
        end
        num = 1 if num.nil? || num < 1
        num
      rescue TTY::Prompt::ConversionError
        puts 'Invalid number, please enter a number.'
        days_custom
      end
    end
  end
end
