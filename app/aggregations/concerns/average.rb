# frozen_string_literal: true

require_relative 'average/daily'
require 'active_support/core_ext/numeric/conversions'

module Aggregations
  module Concerns
    module Average
      include Aggregations::Concerns::Average::Daily

      WEEKS_IN_YEAR = 52.1429
      MONTHS_IN_YEAR = 12
      QUARTERS_IN_YEAR = 4
      YEARS_IN_YEAR = 0

      private

      def average(transactions)
        use = prompt.select(
          'Select period to calculate averages:',
          enum: '.'
        ) do |menu|
          menu.choice 'Daily', :daily
          menu.choice 'Weekly', :weekly
          menu.choice 'Monthly', :monthly
          menu.choice 'Quarterly', :quarterly
          menu.choice 'Yearly', :yearly
        end

        transactions = filters(transactions) unless use == :yearly

        send(use, transactions)
      end

      # output -
      # weekly average (all)
      # per month weekly average - |date-range|avg|
      # per quarter weekly average - |date-range|avg|
      # per year weekly average - |date-range|avg|
      def weekly(models); end

      # output -
      # monthly average (all)
      # per quarter monthly average - |date-range|avg|
      # per year monthly average - |date-range|avg|
      def monthly(models); end

      # output -
      # quarterly average (all)
      # per year quarterly average - |date-range|avg|
      def quarterly(models); end

      # output -
      # yearly average (all)
      def yearly(models)
        compute_yearly(models)
      end

      # rubocop:disable Metrics/AbcSize
      def calculate_initial_values(groups)
        groups.each_key do |k|
          groups[k] = { values: groups[k] }
        end
        groups.each_value do |g|
          g[:income] = g[:values].reject(&:is_debit).sum(&:amount)
          g[:expenses] = g[:values].filter(&:is_debit).sum(&:amount)
          g[:total] = g[:income] - g[:expenses]
          g[:count] = g[:values].size
          g.delete :values
        end
      end

      def calculate_average_across_all_groups(grouped)
        [
          grouped.values.sum { |g| g[:income] } / grouped.size,
          grouped.values.sum { |g| g[:expenses] } / grouped.size,
          grouped.values.sum { |g| g[:total] } / grouped.size,
          grouped.values.sum { |g| g[:count] } / grouped.size
        ]
      end
      # rubocop:enable Metrics/AbcSize

      def print_all_averages(averages, period)
        puts "#{period} Income Average:   #{averages.first.to_s(:currency)}"
        puts "#{period} Expenses Average: #{averages[1].to_s(:currency)}"
        puts "#{period} Count Average:    #{averages.last}"
        puts "#{period} Total Average:    #{averages[2].to_s(:currency)}"
      end

      # rubocop:disable Metrics/AbcSize
      def print_groupings(groups)
        return if groups.empty?

        puts 'Too many groupings, print first 150...' unless groups.size < 150

        table = TTY::Table.new(
          %w[Range Income Expenses Count Total],
          groups.keys.slice(0, 150).map do |k|
            group = groups[k]
            [
              k,
              group[:income].to_s(:currency),
              group[:expenses].to_s(:currency),
              group[:count],
              group[:total].to_s(:currency)
            ]
          end
        )
        puts table.render(:ascii)
      end

      def print_range_table(groups)
        return if groups.empty?

        puts 'Too many groupings, print first 150...' unless groups.size < 150

        table = TTY::Table.new(
          ['Range', 'Ave Income', 'Ave Expenses', 'Ave Count', 'Ave Total'],
          groups.keys.slice(0, 150).map do |k|
            group = groups[k]
            [
              "#{k.last.strftime('%m/%d/%Y')} " \
              "- #{k.first.strftime('%m/%d/%Y')}",
              (group[:income] / group[:num_periods]).to_s(:currency),
              (group[:expenses] / group[:num_periods]).to_s(:currency),
              (group[:count] / group[:num_periods]),
              (group[:total] / group[:num_periods]).to_s(:currency)
            ]
          end
        )
        puts table.render(:ascii)
      end
      # rubocop:enable Metrics/AbcSize

      def num_days_in_range(range)
        (range.last.to_date - range.first.to_date).to_i + 1
      end

      def transaction_model
        @transaction_model ||= proxy.model(:transaction)
      end
    end
  end
end
