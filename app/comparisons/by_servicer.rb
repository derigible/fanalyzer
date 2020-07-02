# frozen_string_literal: true

require_relative './concerns/date'

module Comparisons
  class ByServicer
    include Comparisons::Concerns::Date
    attr_accessor :proxy, :prompt

    def initialize(db_proxy, tty_prompt)
      @proxy = db_proxy
      @prompt = tty_prompt
    end

    def run!
      compare

      compare while prompt.yes?('Do another compare by servicer?')
    end

    private

    def compare
      servicer = find_servicer
      compared = comparisons(transaction_model.where(servicer: servicer)).to_a
      print_compared(compared)
      print_differences(compared)
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
