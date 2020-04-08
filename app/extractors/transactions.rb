# frozen_string_literal: true

require 'ostruct'

module Extractors
  class Transactions
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
        row = create_transaction_struct(r)
        add_to_transactions(row)
        add_to_servicer(row)
        add_to_category(row)
      end
    end

    private

    attr_reader :file, :headers, :d_format

    def create_transaction_struct(record)
      OpenStruct.new record.to_h.transform_keys(&:downcase)
    end

    def extract_field(record, field)
      return Date.strptime(record[headers[:date]], d_format) if field == 'date'

      record[headers[field]]
    end
  end
end
