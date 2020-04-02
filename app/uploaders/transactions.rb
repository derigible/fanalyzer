# frozen_string_literal: true

module Uploaders
  class Transactions
    def initialize(database_proxy, file, headers, date_format)
      @file = file
      @headers = headers
      @d_format = date_format
      @db_proxy = database_proxy
    end

    def upload!
      transactions = db_proxy.model(:transaction)
      CSV.open(file, headers: true).each do |r|
        debugger
        r_date = date(r)
        trans = transactions.where(
          date: r_date,
          description: r[headers['description']],
          amount: r[headers['amount']]
        )
        puts trans.size
      end
    end

    private

    attr_reader :file, :headers, :db_proxy, :d_format

    def date(record)
      Date.strptime(record[headers[:date]], d_format)
    end
  end
end
