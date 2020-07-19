# frozen_string_literal: true

require_relative 'base'

module Comparisons
  class ByServicer < Base
    def run!
      run_compare

      run_compare while prompt.yes?('Do another compare by servicer?')
    end

    private

    def run_compare
      servicer = find_servicer
      compare(transaction_model.where(servicer: servicer))
    end

    def find_servicer
      servicers = servicer
      prompt.select(
        'Select servicer to compare by (type to search)', filter: true
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
