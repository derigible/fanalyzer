# frozen_string_literal: true

require_relative 'concerns/sum'
require_relative 'concerns/average'

module Aggregations
  class Base
    include Aggregations::Concerns::Sum
    include Aggregations::Concerns::Average
    attr_accessor :proxy, :prompt

    def initialize(db_proxy, tty_prompt)
      @proxy = db_proxy
      @prompt = tty_prompt
      @sparse_preference = true
    end

    def run!
      aggregate

      aggregate while prompt.yes?(rerun_prompt)
    end

    private

    def filters(models)
      if prompt.yes?('Apply additional filters?')
        date_filters(models)
      else
        models
      end
    end

    def rerun_prompt
      raise NotImplementedError
    end

    def choose_aggregation
      prompt.select(
        'Select aggregation to use (type to search)',
        enum: '.'
      ) do |menu|
        menu.choice 'Sum', :sum
        menu.choice 'Average', :average
      end
    end

    def sparse_preference
      @sparse_preference = prompt.yes?(
        'Use sparse output? (will not fill in periods missing values)'
      )
    end
  end
end
