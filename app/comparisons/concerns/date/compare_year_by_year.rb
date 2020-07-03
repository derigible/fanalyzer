# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date_and_time/calculations'
require 'active_support/core_ext/array/access'

module Comparisons
  module Concerns
    module Date
      module CompareYearByYear
        private

        def compare_year_by_year(models, num_periods_between, iteration)
          [
            make_comparison(
              iteration,
              first_year_period(iteration),
              models
            ),
            make_comparison(
              iteration,
              second_year_period(num_periods_between, iteration),
              models
            ),
          ]
        end

        def first_year_period(iteration)
          year = (iteration + 1).year.ago
          [year.beginning_of_year, year.end_of_year]
        end

        def second_year_period(num_periods_between, iteration)
          year = (iteration + 1 + num_periods_between).year.ago
          [year.beginning_of_year, year.end_of_year]
        end
      end
    end
  end
end
