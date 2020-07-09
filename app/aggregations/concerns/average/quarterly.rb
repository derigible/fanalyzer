# frozen_string_literal: true

require_relative 'base'

module Aggregations
  module Concerns
    module Average
      class Quarterly < Base
        private

        def do_ranges
          do_range(grouped, :year)
        end

        def ave_kind
          :quarter
        end

        def printable_ave_kind
          'Quarterly'
        end
      end
    end
  end
end
