# frozen_string_literal: true

require_relative 'concerns/sum'
require_relative 'base'

module Aggregations
  class ByServicer < Base
    private

    def rerun_prompt
      'Do another aggregate by category?'
    end

    def aggregate
      servicer = find_servicer
      transactions = transaction_model.where(servicer: servicer)
      aggregation = choose_aggregation

      send(aggregation, transactions)
    end

    def find_servicer
      servicers = servicer
      prompt.select(
        'Select servicer to search by (type to search)', filter: true
      ) do |menu|
        servicers.each do |c|
          menu.choice c.name, c
        end
      end
    end

    def servicer
      @servicer ||= proxy.model(:servicer)
    end
  end
end
