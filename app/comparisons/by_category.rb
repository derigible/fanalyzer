# frozen_string_literal: true

require_relative './concerns/transaction'

module Comparisons
  class ByCategory
    include Comparisons::Concerns::Transaction
    attr_accessor :proxy, :prompt

    def initialize(db_proxy, tty_prompt)
      @proxy = db_proxy
      @prompt = tty_prompt
    end

    def run!
      compare

      compare while prompt.yes?('Do another compare by category?')
    end

    private

    def compare
      category = find_category
      compared = comparisons(transaction_model.where(category: category)).to_a
      print_compared(compared)
      print_differences(compared)
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
