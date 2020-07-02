# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date_and_time/calculations'

Comparison = Struct.new(:description, :transactions, :sum)

module Comparisons
  module Concerns
    module Date
      private

      def date_comparisons(models)
        num_periods_between = ask_num_periods_between
        num_comparisons = ask_number_comparisons
        period = comparison_period
        comps = []
        (0..num_comparisons).each do |i|
          comps << do_compare(models, num_periods_between, period, i)
        end
        comps
      end

      def do_compare(models, num_periods_between, period, iteration)
        if period.is_a? Numeric
          compare_by_number(models, num_periods_between, period, iteration)
        elsif period == :month
          compare_month_by_month(models, num_periods_between, period, iteration)
        elsif period == :quarter
          compare_quarter_by_quarter(
            models, num_periods_between, period, iteration
          )
        elsif period == :year
          compare_year_by_year(models, num_periods_between, period, iteration)
        end
      end

      def compare_month_by_month(models, num_periods_between, period, iteration); end

      def compare_quarter_by_quarter(models, num_periods_between, period, iteration); end

      def compare_by_number(models, num_periods_between, period, iteration)
        # get all transactions between the first period and sum
        iteration_period_offset = (period * iteration)

        first_start_period = (iteration_period_offset + period).days.ago
        first_end_period = iteration_period_offset.days.ago
        first = models.where(date: first_start_period..first_end_period)

        # get all transactions between the second period and sum
        second_start_period = (
          (iteration_period_offset * num_periods_between) + period
        ).days.ago
        second_end_period = (
          iteration_period_offset * num_periods_between
        ).days.ago
        second = models.where(date: second_start_period..second_end_period)
        [
          Comparison.new(
            description: "Period #{iteration} First",
            transactions: first,
            sum: first.to_a.sum { |t| t.is_debit ? t.amount : -t.amount }
          ),
          Comparison.new(
            description: "Period #{iteration} Second",
            transactions: second,
            sum: second.to_a.sum { |t| t.is_debit ? t.amount : -t.amount }
          ),
        ]
      end

      def compare_year_by_year(models, num_periods_between, period, iteration); end

      def comparison_period
        use = prompt.select(
          'Choose comparison period type:', enum: '.'
        ) do |menu|
          menu.choice '7 days', :days_7
          menu.choice '30 days', :days_30
          menu.choice 'Custom number days', :days_custom
          menu.choice 'Month ', :month
          menu.choice 'Quarter', :quarter
          menu.choice 'Year', :year
        end
        return use if %i[month quarter year].include?(use)

        send(use)
      end

      def ask_number_comparisons
        num_comparisons = prompt.ask(
          'How many comparisons? (Numbers less than 1 and blank will default to 1)'
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
