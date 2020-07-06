# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date_and_time/calculations'
require 'active_support/core_ext/array/access'

module Comparisons
  module Concerns
    module Date
      module CompareMonthToDate
        private

        def compare_month_to_date(models, num_periods_between, iteration)
          [
            make_comparison(
              iteration,
              first_month_to_date_period(iteration),
              models
            ),
            make_comparison(
              iteration,
              second_month_to_date_period(num_periods_between, iteration),
              models
            ),
          ]
        end

        def first_month_to_date_period(iteration)
          today = ::Date.today
          day_of_month = today.day
          month_of_year = today.month
          year = today.year
          [
            ::Date.new(year - iteration, month_of_year, 1),
            ::Date.new(year - iteration, month_of_year, day_of_month)
          ]
        end

        def second_month_to_date_period(num_periods_between, iteration)
          today = ::Date.today
          day_of_month = today.day
          month_of_year = today.month
          year = today.year
          [
            ::Date.new(
              year - iteration - num_periods_between, month_of_year, 1
            ),
            ::Date.new(
              year - iteration - num_periods_between,
              month_of_year,
              day_of_month
            )
          ]
        end
      end
    end
  end
end
