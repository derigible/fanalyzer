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
        # per week daily average expenses - |date-range|avg|
        # per week daily average income - |date-range|avg|
        # per week daily average total - |date-range|avg|
        # per week daily average count - |date-range|avg|
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
        end

        def group_by_week(grouped)
          sorted_grouped_keys = grouped.keys.sort
          first_date, last_date = first_and_last_date(sorted_grouped_keys)
          weeks = weeks_from_years_between(first_date, last_date)
          weeks += last_date.cweek + (WEEKS_IN_YEAR - first_date.cweek)
          make_week_groupings(weeks, grouped, sorted_grouped_keys)
        end

        def first_and_last_date(sorted_grouped_keys)
          [
            sorted_grouped_keys.first,
            sorted_grouped_keys.last
          ]
        end

        def make_week_groupings(weeks, grouped, sorted_grouped_keys)
          # TODO: not performant, but small number of ranges so may not matter
          (0..weeks.floor).each_with_object({}) do |i, new_groupings|
            range = i.weeks.ago.all_week
            sorted_grouped_keys.reverse.each do |sgk|
              break if range.first > sgk
              next if range.last < sgk

              new_groupings[range] ||= {
                income: 0, expenses: 0, count: 0, total: 0
              }
              update_week_group(new_groupings[range], grouped[sgk])
            end
          end
        end

        def update_week_group(group, grouped)
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
