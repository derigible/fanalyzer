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
      module Daily
        private

        # output -
        # daily average expenses (all)
        # daily average income (all)
        # daily average total (all)
        # daily average count (all)
        # per week daily average expenses - |date-range|avgs|
        # per month daily average expenses - |date-range|avgs|
        # per quarter daily average expenses - |date-range|avgs|
        # per year daily average expenses - |date-range|avgs|
        def daily(models)
          grouped = models.to_a.group_by(&:date)
          calculate_initial_values(grouped)
          print_groupings(grouped)
          print_all_averages(
            calculate_average_across_all_groups(grouped),
            'Daily'
          )
          do_range(grouped, :week, :cweek)
          do_range(grouped, :month)
          do_range(grouped, :quarter)
          do_range(grouped, :year)
        end

        def do_range(grouped, type, date_accessor = type)
          return unless prompt.yes?("See daily averages per #{type}}?")

          grouped_by = group_by(grouped, type, date_accessor)
          print_range_table(grouped_by)
        end

        def group_by(grouped, type, date_accessor = type)
          sorted_grouped_keys = grouped.keys.sort
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
              new_groupings[range] ||= {
                income: 0,
                expenses: 0,
                count: 0,
                total: 0,
                num_periods: num_periods(range)
              }
              break if range.first > sgk
              next if range.last < sgk

              update_group(new_groupings[range], grouped[sgk])
            end
          end
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
          num_periods_between + last_date.send(date_accessor) + (
            period_constant - first_date.send(date_accessor)
          )
        end

        def update_group(group, grouped)
          group[:income] += grouped[:income]
          group[:expenses] += grouped[:expenses]
          group[:count] += grouped[:count]
          group[:total] += grouped[:total]
        end

        def periods_from_years_between(first_date, last_date, period_constant)
          if (last_date - first_date).is_a? ::Date
            (last_date.year - first_date.year) * period_constant
          else
            0
          end
        end
      end
    end
  end
end
