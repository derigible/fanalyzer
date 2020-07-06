# frozen_string_literal: true

require_relative 'concerns/sum'
require_relative 'base'

module Aggregations
  class ByDate < Base
    private

    def rerun_prompt
      'Do another aggregate by date?'
    end

    def aggregate
      transactions = transaction_model
      aggregation = choose_aggregation

      send(aggregation, transactions)
    end
  end
end
