# frozen_string_literal: true

require_relative 'base'

module Aggregations
  module Concerns
    module Average
      class Daily < Base
        def initialize(models, prompt)
          super(models, prompt)
          @grouped = models.to_a.group_by(&:date)
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
          do_range(grouped, :week, :cweek)
          do_range(grouped, :month)
          do_range(grouped, :quarter)
          do_range(grouped, :year)
        end

        def num_periods_in_range(range)
          (range.last.to_date - range.first.to_date).to_i + 1
        end

        def ave_kind
          'Daily'
        end
      end
    end
  end
end
