# frozen_string_literal: true

require_relative 'date'
require 'active_support/core_ext/numeric/conversions'

module Aggregations
  module Concerns
    module Average
      private

      def average(transactions)
        transactions = filters(transactions).to_a
        print_transactions(transactions)
      end

      def filters(models)
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

        send(use, models)
      end

      # output -
      # daily average expenses (all)
      # daily average income (all)
      # daily average total (all)
      # per week daily average expenses - |date-range|avg|
      # per week daily average income - |date-range|avg|
      # per week daily average total - |date-range|avg|
      # per month daily average expenses - |date-range|avg|
      # per month daily average income - |date-range|avg|
      # per month daily average total - |date-range|avg|
      # per quarter daily average expenses - |date-range|avg|
      # per quarter daily average income - |date-range|avg|
      # per quarter daily average total - |date-range|avg|
      # per year daily average expenses - |date-range|avg|
      # per year daily average income - |date-range|avg|
      # per year daily average total - |date-range|avg|
      def daily(models)
        grouped = models.to_a.group_by(&:date)
        calculate_initial_values(grouped)
        print_groupings(grouped)
        print_all_averages(calculate_average_across_all_groups(grouped))
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

      def calculate_initial_values(groups)
        groups.each_key do |k|
          groups[k] = { values: groups[k] }
        end
        groups.each_value do |g|
          g[:income] = g[:values].reject(&:is_debit).sum(&:amount)
          g[:expenses] = g[:values].filter(&:is_debit).sum(&:amount)
          g[:total] = g[:income] - g[:expenses]
        end
      end

      def calculate_average_across_all_groups(grouped)
        [
          grouped.values.sum { |g| g[:income] } / grouped.size,
          grouped.values.sum { |g| g[:expenses] } / grouped.size,
          grouped.values.sum { |g| g[:total] } / grouped.size
        ]
      end

      def print_all_averages(averages)
        puts "Daily Income Average:   #{averages.first.to_s(:currency)}"
        puts "Daily Expenses Average: #{averages[1].to_s(:currency)}"
        puts "Daily Total Average:    #{averages.last.to_s(:currency)}"
      end

      def print_groupings(groups)
        return if groups.empty?

        table = TTY::Table.new(
          %w[Range Income Expenses Total],
          groups.keys.map do |k|
            group = groups[k]
            [
              k,
              group[:income].to_s(:currency),
              group[:expenses].to_s(:currency),
              group[:total].to_s(:currency)
            ]
          end
        )
        puts table.render(:ascii)
      end

      def transaction_model
        @transaction_model ||= proxy.model(:transaction)
      end
    end
  end
end
