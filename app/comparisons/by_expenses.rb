# frozen_string_literal: true

require_relative './concerns/transaction'

module Comparisons
  class ByExpenses
    include Comparisons::Concerns::Transaction
    attr_accessor :proxy, :prompt

    def initialize(db_proxy, tty_prompt)
      @proxy = db_proxy
      @prompt = tty_prompt
    end

    def run!
      compare

      compare while prompt.yes?('Do another compare by expenses?')
    end

    private

    def compare
      compared = comparisons(transaction_model.where(is_debit: true)).to_a
      print_compared(compared)
      print_differences(compared)
    end
  end
end
