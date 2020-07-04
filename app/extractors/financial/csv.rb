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
        row = record.to_h.transform_keys(&:downcase)
        t = OpenStruct.new
        headers.each_key do |h|
          t[h] = extract_field(row, h)
        end
        map_debit(t)
        t
      end

      def extract_field(record, field)
        if field == 'date'
          return Date.strptime(
            record[headers[:date]], d_format
          )
        end

        headers[field] == ':skip' ? nil : record[headers[field]]
      end

      def extract_transaction(transaction)
        transaction.servicer = servicer(transaction)
        transaction.category = category(transaction)
        normalize_transaction_data(transaction)
        transaction
      end

      def servicer(row)
        name = row[:servicer]
        servicers[name] || begin
          servicers[name] = OpenStruct.new name: name
        end
      end

      def category(row)
        name = row[:category]
        categories[name] || begin
          categories[name] = OpenStruct.new name: name
        end
      end

      def normalize_transaction_data(transaction)
        transaction.date = extract_field(transaction, 'date')
      end

      def map_debit(transaction)
        # is_debit could get complicated. break it for now to clean
        # up the code and to allow for future debit detection if needed
        transaction.is_debit = transaction.type&.downcase == 'debit'
        transaction.delete_field 'type'
      end
    end
  end
end
