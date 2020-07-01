# frozen_string_literal: true

require_relative 'date'

module Queries
  module Concerns
    module Transaction
      include Queries::Concerns::Date

      private

      def filters(models)
        date_filters(models)
      end

      def print_transactions(transactions)
        table = TTY::Table.new(
          transactions.first.table_keys,
          transactions.map(&:to_table_row)
        )
        puts table.render(:ascii)
      end

      def print_stats(transactions)
        puts
        total_table = TTY::Table.new(
          %i[Count Total],
          [[transactions.count, transactions.sum(&:amount)]]
        )
        puts total_table.render(:ascii)
      end

      def transaction_model
        @transaction_model ||= proxy.model(:transaction)
      end
    end
  end
end
