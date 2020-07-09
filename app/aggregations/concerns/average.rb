# frozen_string_literal: true

require 'active_support/core_ext/numeric/conversions'
require_relative 'average/daily'
require_relative 'average/weekly'
require_relative 'average/monthly'
require_relative 'average/quarterly'
require_relative 'average/yearly'

module Aggregations
  module Concerns
    module Average
      private

      def average(transactions)
        use = prompt.select(
          'Select period to calculate averages:',
          enum: '.'
        ) do |menu|
          menu.choice 'Daily', :daily
          menu.choice 'Weekly', :weekly
          menu.choice 'Monthly', :monthly
          menu.choice 'Quarterly', :quarterly
          menu.choice 'Yearly', :yearly
        end

        transactions = filters(transactions) unless use == :yearly

        send(use, transactions)
      end

      def daily(models)
        Daily.new(models, prompt).run!
      end

      # output -
      # weekly average (all)
      # per month weekly average - |date-range|avg|
      # per quarter weekly average - |date-range|avg|
      # per year weekly average - |date-range|avg|
      def weekly(models)
        Weekly.new(models, prompt).run!
      end

      # output -
      # monthly average (all)
      # per quarter monthly average - |date-range|avg|
      # per year monthly average - |date-range|avg|
      def monthly(models)
        Monthly.new(models, prompt).run!
      end

      # output -
      # quarterly average (all)
      # per year quarterly average - |date-range|avg|
      def quarterly(models)
        Quarterly.new(models, prompt).run!
      end

      # output -
      # yearly average (all)
      def yearly(models)
        Yearly.new(models, prompt).run!
      end

      def transaction_model
        @transaction_model ||= proxy.model(:transaction)
      end
    end
  end
end
