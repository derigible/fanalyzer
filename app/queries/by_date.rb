# frozen_string_literal: true

require_relative './concerns/transaction'

module Queries
  class ByDate
    include Queries::Concerns::Transaction
    attr_accessor :proxy, :prompt

    def initialize(db_proxy, tty_prompt)
      @proxy = db_proxy
      @prompt = tty_prompt
    end

    def run!
      query

      query while prompt.yes?('Do another query by date?')
    end

    private

    def query
      transactions = filters(transaction_model).to_a
      print_transactions(transactions)
      print_stats(transactions)
    end
  end
end
