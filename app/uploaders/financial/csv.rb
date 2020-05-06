# frozen_string_literal: true

require 'csv'
require_relative '../../interactions/select_headers'
require_relative '../../interactions/select_file'
require_relative '../../interactions/select_date_format'
require_relative '../../interactions/new_servicer'
require_relative '../../interactions/new_category'
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
        update_servicers(servicers)
        udpate_categories(categories)
        update_transactions(transactions)
      end

      private

      def update_servicers(servicers)
        servicers.each_value do |s|
          servicer = servicer_model[name: s.name]
          if servicer.nil?
            Interactions::NewServicer.new(s, servicer_model, prompt).run!
          else
            s.id = servicer.id
          end
        end
      end

      def update_categories(categories)
        categories.each_value do |c|
          category = category_model[name: c.name]
          if category.nil?
            Interactions::NewCategory.new(c, category_model, prompt).run!
          else
            c.id = category.id
          end
        end
      end

      def update_transactions(transactions)
        new_ts = detect_new_transactions(transactions)
        return unless new_ts.size.positive?

        action = prompt.prompt(
          "There are #{new_ts.size} new transactions. What would you like to do?"
        ) do |menu|
          menu.choice 'Save without reviewing', :save
          menu.choice 'Review each transaction', :review
        end
        send(action, new_ts)
      end

      def save(transactions)
        transactions.each do |t|
          next if t.servicer.id == 'remove'

          transaction_model.create(
            date: t.date,
            description: t.description,
            amount: t.amount,
            is_debit: t.is_debit,
            category_id: t.category.id,
            servicer_id: t.servicer.id
            # TODO: add source_id when sources are introduced
          )
        end
      end

      def review(transactions); end

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

      def detect_new_transactions(transactions)
        transactions.each_with_object([]) do |t, new_transactions|
          next unless transaction_model[
            date: t.date, amount: t.amount, is_debit: t.is_debit
          ].nil?

          new_transactions << t
        end
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
