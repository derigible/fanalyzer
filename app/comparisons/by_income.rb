# frozen_string_literal: true

require_relative './concerns/transaction'

module Comparisons
  class ByIncome
    include Comparisons::Concerns::Transaction
    attr_accessor :proxy, :prompt

    def initialize(db_proxy, tty_prompt)
      @proxy = db_proxy
      @prompt = tty_prompt
    end

    def run!
      compare

      query while prompt.yes?('Do another compare by income?')
    end

    private

    def compare
      compared = comparisons(transaction_model.where(is_debit: false)).to_a
      print_compared(compared)
      print_differences(compared)
    end
  end
end
