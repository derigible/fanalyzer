# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date_and_time/calculations'
require 'active_support/core_ext/array/access'
require 'active_support/core_ext/integer/time'

module Comparisons
  module Concerns
    module Date
      module CompareMonthByMonth
        private

        def compare_month_by_month(
          models, num_periods_between, iteration
        )
          [
            make_comparison(
              iteration,
              first_month_period(iteration),
              models
            ),
            make_comparison(
              iteration,
              second_month_period(num_periods_between, iteration),
              models
            ),
          ]
        end

        def first_month_period(iteration)
          # we don't want to show the current month, so add 1
          month = (iteration + 1).months.ago
          [month.beginning_of_month, month.end_of_month]
        end

        def second_month_period(num_periods_between, iteration)
          # we don't want to show the current month, so add 1
          month = (num_periods_between.months + (iteration + 1).months).ago
          [month.beginning_of_month, month.end_of_month]
        end
      end
    end
  end
end
