# frozen_string_literal: true

require_relative 'base'

module Aggregations
  module Concerns
    module Average
      class Weekly < Base
        private

        def do_ranges
          do_range(grouped, :month)
          do_range(grouped, :quarter)
          do_range(grouped, :year)
        end

        def ave_kind
          :week
        end

        def printable_ave_kind
          'Weekly'
        end
      end
    end
  end
end
