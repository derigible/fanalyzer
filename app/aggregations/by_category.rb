# frozen_string_literal: true

require_relative 'base'

module Aggregations
  class ByCategory < Base
    private

    def rerun_prompt
      'Do another aggregate by category?'
    end

    def aggregate
      category = find_category
      transactions = transaction_model.where(category: category)
      aggregation = choose_aggregation

      send(aggregation, transactions)
    end

    def find_category
      categories = category_model
      prompt.select(
        'Select category to search by (type to search)', filter: true
      ) do |menu|
        categories.each do |c|
          menu.choice c.name, c
        end
      end
    end

    def category_model
      @category_model ||= proxy.model(:category)
    end
  end
end
