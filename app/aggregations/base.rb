# frozen_string_literal: true

require_relative 'concerns/sum'

module Aggregations
  class Base
    include Aggregations::Concerns::Sum
    attr_accessor :proxy, :prompt

    def initialize(db_proxy, tty_prompt)
      @proxy = db_proxy
      @prompt = tty_prompt
    end

    def run!
      aggregate

      aggregate while prompt.yes?(rerun_prompt)
    end

    private

    def rerun_prompt
      raise NotImplementedError
    end

    def choose_aggregation
      prompt.select(
        'Select aggregation to use (type to search)',
        enum: '.'
      ) do |menu|
        menu.choice 'Sum', :sum
      end
    end
  end
end
