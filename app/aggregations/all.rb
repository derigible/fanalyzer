# frozen_string_literal: true

require_relative 'concerns/sum'
require_relative 'base'

module Aggregations
  class All < Base
    private

    def rerun_prompt
      'Do another aggregate for all?'
    end

    def aggregate
      transactions = transaction_model
      aggregation = choose_aggregation

      send(aggregation, transactions)
    end
  end
end
