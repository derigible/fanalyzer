# frozen_string_literal: true

require 'active_support/core_ext/numeric/conversions'
require 'active_support/core_ext/integer/time'
require 'active_support/core_ext/date_and_time/calculations'

class Date
  def quarter
    (month / 3.0).ceil
  end
end

class Integer
  # Returns a Duration instance matching the number of quarters provided.
  #
  #   2.quarters # => 2 quarters
  def quarters
    ActiveSupport::Duration.months(self * 3)
  end
  # rubocop:disable Style/Alias
  alias :quarter :quarters
  # rubocop:enable Style/Alias
end

module Aggregations
  module Concerns
    module Average
      class Base
        WEEKS_IN_YEAR = 52.1429
        MONTHS_IN_YEAR = 12
        QUARTERS_IN_YEAR = 4
        YEARS_IN_YEAR = 0
        FMT_TIME_PATTERN = '%m/%d/%Y'

        attr_reader :grouped, :prompt

        def initialize(models, prompt)
          @models = models
          @prompt = prompt
          @sparse_preference = true
        end

        def run!
          calculate_initial_values(grouped)
          print_groupings(grouped)
          print_all_averages(
            calculate_average_across_all_groups_for_given_range(grouped),
            ave_kind
          )
          do_ranges
        end

        private

        def do_ranges
          raise NotImplementedError
        end

        def ave_kind
          raise NotImplementedError
        end

        def do_range(grouped, type, date_accessor = type)
          return unless prompt.yes?(
            "See #{ave_kind.downcase} averages per #{type}?"
          )

          sparse_preference

          grouped_by = group_by(grouped, type, date_accessor)
          print_range_table(grouped_by)
        end

        def sorted_grouped_keys
          @sorted_grouped_keys ||= grouped.keys.sort
        end

        def group_by(grouped, type, date_accessor = type)
          num_periods = number_periods_to_check(
            sorted_grouped_keys, type, date_accessor
          )
          make_groupings(num_periods, grouped, sorted_grouped_keys, type)
        end

        def make_groupings(num_periods, grouped, sorted_grouped_keys, type)
          # TODO: not performant, but small number of ranges so may not matter
          (0..num_periods.ceil).each_with_object({}) do |i, new_groupings|
            range = make_range(i, type)
            sorted_grouped_keys.reverse.each do |sgk|
              make_new_grouping(new_groupings, range) unless @sparse_preference

              break if range.first > sgk
              next if range.last < sgk

              make_new_grouping(new_groupings, range) if @sparse_preference

              update_group(new_groupings[range], grouped[sgk])
            end
          end
        end

        def make_new_grouping(new_groupings, range)
          new_groupings[range] ||= {
            income: 0,
            expenses: 0,
            count: 0,
            total: 0,
            num_periods: num_periods_in_range(range)
          }
        end

        def make_range(num, type)
          num.send(type).ago.send("all_#{type}".to_sym)
        end

        def number_periods_to_check(keys, type, date_accessor = type)
          period_constant = self.class.const_get(
            "#{type.to_s.upcase}S_IN_YEAR".to_sym
          )
          first_date = keys.first
          last_date = keys.last
          num_periods_between = periods_from_years_between(
            first_date, last_date, period_constant
          )
          periods_from_dates(
            first_date,
            last_date,
            num_periods_between,
            date_accessor,
            period_constant
          )
        end

        def update_group(group, grouped)
          group[:income] += grouped[:income]
          group[:expenses] += grouped[:expenses]
          group[:count] += grouped[:count]
          group[:total] += grouped[:total]
        end

        def periods_from_years_between(first_date, last_date, period_constant)
          return unless (last_date - first_date).is_a? ::Date

          (last_date.year - first_date.year) * period_constant
        end

        def periods_from_dates(
          first_date,
          last_date,
          num_periods_between,
          date_accessor,
          period_constant
        )
          last_period_num = last_date.send(date_accessor)
          first_period_num = first_date.send(date_accessor)

          if num_periods_between.nil? && last_date.year == first_date.year
            return last_period_num - first_period_num
          end

          num_periods_between = 0 if num_periods_between.nil?
          num_periods_between + last_period_num + (
            period_constant - first_period_num
          )
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

        def calculate_average_across_all_groups_for_given_range(grouped)
          range = sorted_grouped_keys.first..sorted_grouped_keys.last
          num_periods = num_periods_in_range(range).to_f
          [
            grouped.values.sum { |g| g[:income] } / num_periods,
            grouped.values.sum { |g| g[:expenses] } / num_periods,
            grouped.values.sum { |g| g[:total] } / num_periods,
            grouped.values.sum { |g| g[:count] } / num_periods,
            num_periods,
            range
          ]
        end

        # rubocop:disable Layout/LineLength
        def print_all_averages(averages, period)
          puts "#{period} Income Average:             #{averages.first.to_s(:currency)}"
          puts "#{period} Expenses Average:           #{averages[1].to_s(:currency)}"
          puts "#{period} Count Average:              #{averages[3].to_s(:rounded, precision: 2)}"
          puts "#{period} Total Average:              #{averages[2].to_s(:currency)}"
          puts "Number of #{period.downcase} periods in range: #{averages[4]}"
          puts "Start date and End date of range: #{averages.last.first} - #{averages.last.last}"
          puts
        end
        # rubocop:enable Layout/LineLength

        def print_groupings(groups)
          return if groups.empty?

          puts 'Too many groupings, print first 150...' unless groups.size < 150

          table = TTY::Table.new(
            %w[Range Income Expenses Count Total],
            groups.keys.slice(0, 150).map do |k|
              group = groups[k]
              [
                format_group_key(k),
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
                "#{k.last.strftime(FMT_TIME_PATTERN)} " \
                "- #{k.first.strftime(FMT_TIME_PATTERN)}",
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

        def format_group_key(key)
          key
        end

        def num_periods_in_range(_range)
          raise NotImplementedError
        end

        def sparse_preference
          @sparse_preference = prompt.yes?(
            'Use sparse output? (will not fill in periods missing values)'
          )
        end
      end
    end
  end
end
