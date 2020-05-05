# frozen_string_literal: true

require 'ostruct'

module Extractors
  module Financial
    class Csv
      attr_accessor :transactions, :servicers, :categories

      def initialize(file, headers, date_format)
        @file = file
        @headers = headers
        @d_format = date_format
        @servicers = {}
        @categories = {}
        @transactions = []
      end

      def extract!
        CSV.open(file, headers: true).each do |r|
          transactions << extract_transaction(create_transaction_struct(r))
        end
        [transactions, servicers, categories]
      end

      private

      attr_reader :file, :headers, :d_format

      def create_transaction_struct(record)
        OpenStruct.new record.to_h.transform_keys(&:downcase)
      end

      def extract_field(record, field)
        if field == 'date'
          return Date.strptime(
            record[headers['date']], d_format
          )
        end

        record[headers[field]]
      end

      def extract_transaction(transaction)
        transaction.servicer = servicer(transaction)
        transaction.category = category(transaction)
      end

      def servicer(row)
        name = extract_field(row, :servicer)
        servicers[name] || begin
          servicers[name] = OpenStruct.new name: name
        end
      end

      def category(row)
        name = extract_field(row, :category)
        categories[name] || begin
          categories[name] = OpenStruct.new name: name
        end
      end
    end
  end
end
