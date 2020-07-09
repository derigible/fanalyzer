# frozen_string_literal: true

require_relative 'base'

module Aggregations
  module Concerns
    module Average
      class Monthly < Base
        private

        def do_ranges
          do_range(grouped, :quarter)
          do_range(grouped, :year)
        end

        def ave_kind
          :month
        end

        def printable_ave_kind
          'Monthly'
        end
      end
    end
  end
end
