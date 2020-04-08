# frozen_string_literal: true

require 'csv'
require_relative 'select_headers'
require_relative 'select_file'
require_relative 'select_date_format'
require_relative '../extractors/transactions'
require_relative '../uploaders/transactions'

module Interactions
  class UploadCsv
    attr_reader :prompt, :db_proxy

    def initialize(database_proxy, tty_prompt)
      @db_proxy = database_proxy
      @prompt = tty_prompt
    end

    def run!
      header_selector = Interactions::SelectHeaders.new(db_proxy, prompt)
      headers = header_selector.run!
      date_format = select_date_format(header_selector.id)
      extract_transactions_from_csv(
        select_file, headers, date_format
      )
    end

    private

    def extract_transactions_from_csv(file, headers, date_format)
      Extractors::Transactions.new(file, headers, date_format).extract!
    end

    def save_transactions(file, headers, date_format)
      Uploaders::Transactions.new(file, headers, date_format).extract!
    end

    def select_file
      Interactions::SelectFile.new(prompt, 'csv').run!
    end

    def select_date_format(headers_id)
      Interactions::SelectDateFormat.new(db_proxy, prompt).run!(headers_id)
    end
  end
end
