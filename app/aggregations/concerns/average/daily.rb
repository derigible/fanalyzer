# frozen_string_literal: true

require 'active_support/core_ext/numeric/conversions'
require 'active_support/core_ext/date_and_time/calculations'

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
          do_weekly(grouped)
        end

        def do_weekly(grouped)
          return unless prompt.yes?('See daily averages per week?')

          grouped_by_week = group_by_week(grouped)
          print_range_table(grouped_by_week)
          do_monthly(grouped)
        end

        def do_monthly(grouped)
          return unless prompt.yes?('See daily averages per month?')

          grouped_by_month = group_by_month(grouped)
          print_range_table(grouped_by_month)
          do_quarterly(grouped)
        end

        def do_quarterly(grouped)
          return unless prompt.yes?('See daily averages per quarter?')

          grouped_by_quarter = group_by_quarter(grouped)
          print_range_table(grouped_by_quarter)
          do_yearly(grouped)
        end

        def do_yearly(grouped)
          return unless prompt.yes?('See daily averages per year?')

          grouped_by_year = group_by_year(grouped)
          print_range_table(grouped_by_year)
          do_yearly(grouped)
        end

        def group_by_week(grouped)
          sorted_grouped_keys = grouped.keys.sort
          first_date, last_date = first_and_last_date(sorted_grouped_keys)
          num_weeks = weeks_from_years_between(first_date, last_date)
          num_weeks += last_date.cweek + (WEEKS_IN_YEAR - first_date.cweek)
          make_groupings(num_weeks, grouped, sorted_grouped_keys, :weeks)
        end

        def first_and_last_date(sorted_grouped_keys)
          [
            sorted_grouped_keys.first,
            sorted_grouped_keys.last
          ]
        end

        def make_groupings(num_periods, grouped, sorted_grouped_keys, type)
          # TODO: not performant, but small number of ranges so may not matter
          (0..num_periods.floor).each_with_object({}) do |i, new_groupings|
            range = i.send(type).ago.all_week
            sorted_grouped_keys.reverse.each do |sgk|
              break if range.first > sgk
              next if range.last < sgk

              new_groupings[range] ||= {
                income: 0, expenses: 0, count: 0, total: 0
              }
              update_group(new_groupings[range], grouped[sgk])
            end
          end
        end

        def update_group(group, grouped)
          group[:income] += grouped[:income]
          group[:expenses] += grouped[:expenses]
          group[:count] += grouped[:count]
          group[:total] += grouped[:total]
        end

        def weeks_from_years_between(first_date, last_date)
          if (last_date - first_date).is_a? ::Date
            (last_date.year - first_date.year) * WEEKS_IN_YEAR
          else
            0
          end
        end
      end
    end
  end
end
