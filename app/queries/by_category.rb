# frozen_string_literal: true

require_relative './concerns/transaction'

module Queries
  class ByCategory
    include Queries::Concerns::Transaction
    attr_accessor :proxy, :prompt, :statements

    def initialize(db_proxy, tty_prompt)
      @proxy = db_proxy
      @prompt = tty_prompt
      @statements = []
    end

    def run!
      query

      query while prompt.yes?('Do another query by category?')
    end

    private

    def query
      category = find_category
      transactions = transaction_model.where(category: category).to_a
      print_transactions(transactions)
      print_stats(transactions)
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
