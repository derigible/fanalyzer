# frozen_string_literal: true

require_relative 'base'

module Aggregations
  module Concerns
    module Average
      class Yearly < Base
        private

        def do_ranges; end

        def ave_kind
          :year
        end

        def printable_ave_kind
          'Yearly'
        end
      end
    end
  end
end
