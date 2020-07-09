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
  alias :quarter :quarters
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

        DAYS_IN_DAYS = 7
        DAYS_IN_WEEK = 7
        DAYS_IN_MONTH = 30
        DAYS_IN_QUARTER = 90
        DAYS_IN_YEAR = 365

        attr_reader :grouped, :prompt

        def initialize(models, prompt)
          @models = models
          @prompt = prompt
          @sparse_preference = true
          @grouped = models.to_a.group_by do |m|
            m.date.send("beginning_of_#{ave_kind}")
          end
        end

        def run!
          calculate_initial_values(grouped)
          print_groupings(grouped)
          print_all_averages(
            calculate_average_across_all_groups_for_given_range(
              grouped, ave_kind
            ),
            printable_ave_kind
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

        def printable_ave_kind
          raise NotImplementedError
        end

        def do_range(grouped, type)
          return unless prompt.yes?(
            "See #{printable_ave_kind} averages per #{type}?"
          )

          sparse_preference

          grouped_by = group_by(grouped, type)
          print_range_table(grouped_by)
        end

        def sorted_grouped_keys
          @sorted_grouped_keys ||= grouped.keys.sort
        end

        def group_by(grouped, type)
          num_periods = num_periods_in_range(
            sorted_grouped_keys, type
          )
          make_groupings(num_periods, grouped, type)
        end

        def make_groupings(num_periods, grouped, type)
          # TODO: not performant, but small number of ranges so may not matter
          reversed_grouped_keys = sorted_grouped_keys.reverse
          (0..num_periods).each_with_object({}) do |i, new_groupings|
            range = make_range(reversed_grouped_keys.first, i, type)
            reversed_grouped_keys.each do |sgk|
              unless @sparse_preference
                make_new_grouping(new_groupings, range)
              end

              break if range.first > sgk
              next if range.last < sgk

              if @sparse_preference
                make_new_grouping(new_groupings, range)
              end

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
            num_periods: num_periods_in_range(range, ave_kind)
          }
        end

        def make_range(last_date, num, type)
          (last_date.to_date - num.send(type)).send("all_#{type}".to_sym)
        end

        def update_group(group, grouped)
          group[:income] += grouped[:income]
          group[:expenses] += grouped[:expenses]
          group[:count] += grouped[:count]
          group[:total] += grouped[:total]
        end

        # get beginning of last period, get prev_period until
        # period == first period
        def num_periods_in_range(range, type)
          last = range.last.to_date.send("beginning_of_#{type}".to_sym)
          first = range.first.to_date.send("beginning_of_#{type}".to_sym)
          count = 0
          loop do
            last = last.send("prev_#{type}".to_sym)
            break unless last >= first

            count += 1
          end
          count
        end

        def sparse_preference
          @sparse_preference = prompt.yes?(
            'Use sparse output? (will not fill in periods missing values)'
          )
        end

        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Layout/LineLength
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

        def calculate_average_across_all_groups_for_given_range(grouped, type)
          range = sorted_grouped_keys.first..sorted_grouped_keys.last
          num_periods = num_periods_in_range(range, type)
          [
            grouped.values.sum { |g| g[:income] } / num_periods,
            grouped.values.sum { |g| g[:expenses] } / num_periods,
            grouped.values.sum { |g| g[:total] } / num_periods,
            grouped.values.sum { |g| g[:count] } / num_periods,
            num_periods + 1, # add one to offset for 0 based indexing
            range
          ]
        end

        def print_all_averages(averages, period)
          puts "#{period} Income Average:             #{averages.first.to_s(:currency)}"
          puts "#{period} Expenses Average:           #{averages[1].to_s(:currency)}"
          puts "#{period} Count Average:              #{averages[3]}"
          puts "#{period} Total Average:              #{averages[2].to_s(:currency)}"
          puts "Number of #{period.downcase} periods in range: #{averages[4]}"
          puts "Start date and End date of range: #{averages.last.first.strftime(FMT_TIME_PATTERN)} - #{averages.last.last.strftime(FMT_TIME_PATTERN)}"
          puts
        end

        def print_groupings(groups)
          return if groups.empty?

          puts 'Too many groupings, print first 150...' unless groups.size < 150

          table = TTY::Table.new(
            %w[Range Income Expenses Count Total],
            groups.keys.slice(0, 150).sort.reverse.map do |k|
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

        def format_group_key(key)
          "#{key.send("end_of_#{ave_kind}".to_sym).strftime(FMT_TIME_PATTERN)} - " \
          "#{key.strftime(FMT_TIME_PATTERN)}"
        end

        def print_range_table(groups)
          return if groups.empty?

          puts 'Too many groupings, print first 150...' unless groups.size < 150

          table = TTY::Table.new(
            ['Range', 'Ave Income', 'Ave Expenses', 'Ave Count', 'Ave Total'],
            groups.keys.slice(0, 150).sort_by(&:first).reverse.map do |k|
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
        # rubocop:enable Layout/LineLength
      end
    end
  end
end
