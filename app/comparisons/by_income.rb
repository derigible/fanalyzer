# frozen_string_literal: true

require_relative 'base'

module Comparisons
  class ByIncome < Base
    def run!
      run_compare

      run_compare while prompt.yes?('Do another compare by income?')
    end

    private

    def run_compare
      compare(transaction_model.where(is_debit: false))
    end
  end
end
