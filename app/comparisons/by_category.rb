# frozen_string_literal: true

require_relative 'base'

module Comparisons
  class ByCategory < Base
    def run!
      run_compare

      run_compare while prompt.yes?('Do another compare by category?')
    end

    private

    def run_compare
      category = find_category
      compare(transaction_model.where(category: category))
    end

    def find_category
      categories = category_model
      prompt.select(
        'Select category to compare by (type to search)', filter: true
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
