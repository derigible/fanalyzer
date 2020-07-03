# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date_and_time/calculations'
require 'active_support/core_ext/array/access'

module Comparisons
  module Concerns
    module Date
      module CompareByNumber
        private

        def compare_by_number(models, num_periods_between, period, iteration)
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
          offset = (period * iteration)
          [(offset + period).days.ago, offset.days.ago]
        end

        def second(num_periods_between, period, iteration)
          offset = (period * iteration) + (period * num_periods_between)
          [(offset + period).days.ago, offset.days.ago]
        end

        def make_comparison(iteration, range, models)
          result = models.where(date: Range.new(*range))
          Comparison.new(
            "Comparison #{iteration + 1}\n" \
            "#{fmt_date(range.second)}\nto\n" \
            "#{fmt_date(range.first)}",
            result,
            sum(result),
            iteration + 1
          )
        end

        def fmt_date(date)
          date.strftime('%m/%d/%Y')
        end

        def sum(result)
          result.to_a.sum { |t| t.is_debit ? t.amount : -t.amount }
        end
      end
    end
  end
end
