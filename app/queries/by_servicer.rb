# frozen_string_literal: true

require_relative './concerns/transaction'

module Queries
  class ByServicer
    include Queries::Concerns::Transaction
    attr_accessor :proxy, :prompt, :statements

    def initialize(db_proxy, tty_prompt)
      @proxy = db_proxy
      @prompt = tty_prompt
      @statements = []
    end

    def run!
      query

      query while prompt.yes?('Do another query by servicer?')
    end

    private

    def query
      servicer = find_servicer
      transactions = filters(transaction_model.where(servicer: servicer)).to_a
      print_transactions(transactions)
      print_stats(transactions)
    end

    def find_servicer
      servicers = servicer
      prompt.select(
        'Select servicer to search by (type to search)', filter: true
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
