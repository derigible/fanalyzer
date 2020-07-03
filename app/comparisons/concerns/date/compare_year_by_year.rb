# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date_and_time/calculations'

module Comparisons
  module Concerns
    module Date
      module CompareYearByYear
        private

        def compare_year_by_year(models, num_periods_between, period, iteration)
          [
            make_comparison(iteration, first(period, iteration), models),
            make_comparison(
              iteration,
              second(num_periods_between, period, iteration),
              models
            ),
          ]
        end

        def first(period, iteration)
          offset = (period * (iteration - 1))
          [(offset + period).days.ago, offset.days.ago]
        end

        def second(num_periods_between, period, iteration)
          offset = period * num_periods_between * iteration
          [(offset + period).days.ago, offset.days.ago]
        end

        def make_comparison(iteration, range, models)
          result = models.where(date: Range.new(*range))
          Comparison.new(
            "Period #{iteration}\n" \
            "#{range.second.strftime('%m/%d/%Y')}\nto\n" \
            "#{range.first.strftime('%m/%d/%Y')}",
            result,
            result.to_a.sum { |t| t.is_debit ? t.amount : -t.amount }
          )
        end
      end
    end
  end
end
