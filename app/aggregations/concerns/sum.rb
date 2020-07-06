# frozen_string_literal: true

require_relative 'date'
require 'active_support/core_ext/numeric/conversions'

module Aggregations
  module Concerns
    module Sum
      include Aggregations::Concerns::Date

      private

      def sum(transactions)
        transactions = filters(transactions).to_a
        print_transactions(transactions)
        print_stats(transactions)
      end

      def filters(models)
        if prompt.yes?('Apply additional filters?')
          date_filters(models)
        else
          models
        end
      end

      def print_transactions(transactions)
        return if transactions.empty?

        table = TTY::Table.new(
          transactions.first.table_keys,
          transactions.map(&:to_table_row)
        )
        puts table.render(:ascii)
      end

      def print_stats(transactions)
        puts
        total_table = TTY::Table.new(
          [
            'Total Transactions',
            '# Income Transactions',
            'Income Total',
            '# Expense Transactions',
            'Expense Total',
            'Total'
          ],
          [transactions_stats(transactions)]
        )
        puts total_table.render(:ascii)
      end

      # rubocop:disable Metrics/AbcSize
      def transactions_stats(transactions)
        [
          transactions.count,
          transactions.count { |t| !t.is_debit },
          transactions.sum { |t| t.is_debit ? 0 : t.amount }.to_s(:currency),
          transactions.count(&:is_debit),
          transactions.sum { |t| t.is_debit ? t.amount : 0 }.to_s(:currency),
          transactions.sum do |t|
            t.is_debit ? -t.amount : t.amount
          end.to_s(:currency)
        ]
      end
      # rubocop:enable Metrics/AbcSize

      def transaction_model
        @transaction_model ||= proxy.model(:transaction)
      end
    end
  end
end
