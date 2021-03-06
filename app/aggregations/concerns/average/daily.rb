# frozen_string_literal: true

require_relative 'base'

module Aggregations
  module Concerns
    module Average
      class Daily < Base
        private

        def do_ranges
          do_range(grouped, :week)
          do_range(grouped, :month)
          do_range(grouped, :quarter)
          do_range(grouped, :year)
        end

        def ave_kind
          :day
        end

        def printable_ave_kind
          'Daily'
        end

        def format_group_key(key)
          key.strftime(FMT_TIME_PATTERN)
        end
      end
    end
  end
end
