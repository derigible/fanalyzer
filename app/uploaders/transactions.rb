# frozen_string_literal: true

require 'ostruct'

module Uploaders
  class Transactions
    def initialize(database_proxy)
      @db_proxy = database_proxy
    end

    def upload!(row); end

    private

    attr_reader :file, :headers, :db_proxy, :d_format

    def upload_row(row)
      srvcr = servicer(row)
      category = category(row)
      trans = transactions_model.where(
        date: extract_field(row, 'date'),
        description: extract_field(row, 'description'),
        amount: extract_field(row, 'amount')
      )
    end

    def servicer(row)
      servicer_model.find_or_create(
        name: extract_value(row, 'servicer').name
      ) do |s|
        s.alt_names = extract_value(row, 'servicer').alt_names
      end
    end

    def category(row)
      category_model.find_or_create(
        name: extract_value(row, 'category').name
      ) do |c|
        c.alt_names = extract_value(row, 'category').alt_names
      end
    end

    def transactions_model
      @transactions_model ||= db_proxy.model(:transaction)
    end

    def servicer_model
      @servicer_model ||= db_proxy.model(:servicer)
    end

    def category_model
      @category_model ||= db_proxy.model(:category)
    end

    def extract_value(row, field); end
  end
end
