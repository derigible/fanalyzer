# frozen_string_literal: true

require_relative 'base'

module Comparisons
  class ByExpenses < Base
    def run!
      run_compare

      run_compare while prompt.yes?('Do another compare by expenses?')
    end

    private

    def run_compare
      compare(transaction_model.where(is_debit: true))
    end
  end
end
