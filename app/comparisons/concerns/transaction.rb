# frozen_string_literal: true

require_relative 'date'
require 'active_support/core_ext/numeric/conversions'

module Comparisons
  module Concerns
    module Transaction
      include Comparisons::Concerns::Date

      private

      def comparisons(models)
        date_comparisons(models)
      end

      def print_compared(compared)
        return if compared.empty?

        headers = compared.map do |c|
          c.map(&:description)
        end.flatten

        values = compared.map do |c|
          c.map(&:sum)
        end.flatten

        table = TTY::Table.new(
          headers,
          [values]
        )
        puts table.render(
          :ascii, alignment: :center, multiline: true
        )
      end

      def print_differences(_compared)
        puts 'Coming soon...'
      end

      def transaction_model
        @transaction_model ||= proxy.model(:transaction)
      end
    end
  end
end
