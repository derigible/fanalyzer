# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date_and_time/calculations'
require 'active_support/core_ext/array/access'

module Comparisons
  module Concerns
    module Date
      module CompareQuarterByQuarter
        private

        def compare_quarter_by_quarter(
          models, num_periods_between, iteration
        )
          [
            make_comparison(
              iteration,
              first_quarter_period(iteration),
              models
            ),
            make_comparison(
              iteration,
              second_quarter_period(num_periods_between, iteration),
              models
            ),
          ]
        end

        def first_quarter_period(iteration)
          quarter = find_first_quarter(iteration)
          [quarter.beginning_of_quarter, quarter.end_of_quarter]
        end

        def second_quarter_period(num_periods_between, iteration)
          quarter = find_second_quarter(num_periods_between, iteration)
          [quarter.beginning_of_quarter, quarter.end_of_quarter]
        end

        def find_first_quarter(iteration)
          month = ((iteration * 3) + 1).months.ago
          quarter = month.beginning_of_quarter
          if quarter == ::Date.today.beginning_of_quarter
            month.last_quarter.beginning_of_quarter
          else
            quarter
          end
        end

        def find_second_quarter(num_periods_between, iteration)
          # multiply num_periods_between by three to match the number
          # of months ago that is expected
          month = ((num_periods_between * 3) + (iteration * 3) + 1).months.ago
          quarter = month.beginning_of_quarter
          if quarter == ::Date.today.beginning_of_quarter
            month.last_quarter.beginning_of_quarter
          else
            quarter
          end
        end
      end
    end
  end
end
