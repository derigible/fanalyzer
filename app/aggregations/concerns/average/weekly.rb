# frozen_string_literal: true

require_relative 'base'

module Aggregations
  module Concerns
    module Average
      class Weekly < Base
        DAYS_IN_WEEK = 7

        def initialize(models, prompt)
          super(models, prompt)
          @grouped = models.to_a.group_by { |m| m.date.beginning_of_week }
        end

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
        def do_ranges
          do_range(grouped, :month)
          do_range(grouped, :quarter)
          do_range(grouped, :year)
        end

        def num_periods_in_range(range)
          last = range.last.to_date.beginning_of_week
          first = range.first.to_date.beginning_of_week
          ((last - first).to_i + 1) / DAYS_IN_WEEK
        end

        def ave_kind
          'Weekly'
        end

        def format_group_key(key)
          "#{key.end_of_week.strftime(FMT_TIME_PATTERN)} - " \
          "#{key.strftime(FMT_TIME_PATTERN)}"
        end
      end
    end
  end
end
