# frozen_string_literal: true

require 'csv'
require_relative '../../interactions/select_headers'
require_relative '../../interactions/select_file'
require_relative '../../interactions/select_date_format'
require_relative '../../extractors/financial/csv'

module Uploaders
  module Financial
    class Csv
      attr_reader :prompt, :db_proxy

      def initialize(database_proxy, tty_prompt)
        @db_proxy = database_proxy
        @prompt = tty_prompt
      end

      def run!
        header_selector = Interactions::SelectHeaders.new(
          header_mapping_model, prompt
        )
        headers = header_selector.run!
        date_format = select_date_format(header_selector.id)
        transactions, servicers, categories = extract_financial_data_from_csv(
          select_file, headers, date_format
        )
      end

      private

      def extract_financial_data_from_csv(file, headers, date_format)
        Extractors::Financial::Csv.new(file, headers, date_format).extract!
      end

      def save_transactions(file, headers, date_format)
        Uploaders::Transactions.new(file, headers, date_format).extract!
      end

      def select_file
        Interactions::SelectFile.new(prompt, 'csv').run!
      end

      def select_date_format(headers_id)
        Interactions::SelectDateFormat.new(header_mapping_model, prompt).run!(
          headers_id
        )
      end

      def header_mapping_model
        @header_mapping_model ||= db_proxy.model(:financial_header_mapping)
      end

      def transaction_model
        @transaction_model ||= db_proxy.model(:transaction)
      end

      def servicer_model
        @servicer_model ||= db_proxy.model(:servicer)
      end

      def category_model
        @category_model ||= db_proxy.model(:category)
      end
    end
  end
end
