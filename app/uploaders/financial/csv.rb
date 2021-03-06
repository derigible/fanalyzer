# frozen_string_literal: true

require 'csv'
require 'date'
require_relative '../../interactions/select_headers'
require_relative '../../interactions/select_file'
require_relative '../../interactions/select_source'
require_relative '../../interactions/select_date_format'
require_relative '../../interactions/new_servicer'
require_relative '../../interactions/new_category'
require_relative '../../interactions/review_transactions'
require_relative '../../extractors/financial/csv'

module Uploaders
  module Financial
    class Csv
      attr_reader :prompt, :db_proxy, :upload_id, :opts

      def initialize(database_proxy, tty_prompt, **opts)
        @db_proxy = database_proxy
        @prompt = tty_prompt
        @opts = opts
      end

      def run!
        upload_id = new_upload
        header_selector = select_headers
        headers = header_selector.run!
        date_format = select_date_format(header_selector.id)
        transactions, servicers, categories = extract_financial_data_from_csv(
          select_file, headers, date_format
        )
        update_servicers(servicers, upload_id)
        update_categories(categories, upload_id)
        update_transactions(transactions, upload_id)
      end

      private

      def new_upload
        source = select_source
        db_proxy.model(:upload).create(source_id: source.id).id
      end

      def update_servicers(servicers, upload_id)
        servicers.each_value do |s|
          servicer = servicer_model[name: s.name]
          if servicer.nil?
            Interactions::NewServicer.new(
              s, servicer_model, prompt, upload_id
            ).run!
          else
            s.id = servicer.mapped_id
          end
        end
      end

      def update_categories(categories, upload_id)
        categories.each_value do |c|
          category = category_model[name: c.name]
          if category.nil?
            Interactions::NewCategory.new(
              c, category_model, prompt, upload_id
            ).run!
          else
            c.id = category.mapped_id
          end
        end
      end

      def update_transactions(transactions, upload_id)
        new_ts = detect_new_transactions(transactions)
        return unless new_ts.size.positive?

        action = prompt.select(
          "Found #{new_ts.size} new transactions. What would you like to do?",
          enum: '.'
        ) do |menu|
          menu.choice 'Save without reviewing', :save
          menu.choice 'Review each transaction', :review
        end
        send(action, new_ts, upload_id)
      end

      def save(transactions, upload_id)
        count = 1
        transactions.each do |t|
          next if t.servicer.id == 'remove'

          puts "Creating new transaction #{count}" unless opts[:quiet]

          create_transaction(t, upload_id)
          count += 1
        end
        puts "Created #{count} tranactions" if opts[:quiet]
      end

      def create_transaction(transaction, upload_id)
        t = transaction_model.create(
          date: transaction.date,
          description: transaction.description,
          amount: transaction.amount,
          is_debit: transaction.is_debit,
          category_id: transaction.category.id,
          servicer_id: transaction.servicer.id,
          upload_id: upload_id
        )

        transaction.labels&.each { |tl| t.add_label(tl) }
      end

      def review(transactions, upload_id)
        save(
          Interactions::ReviewTransactions.new(
            servicer_model,
            category_model,
            label_model,
            transaction_model,
            prompt,
            upload_id,
            transactions
          ).run!,
          upload_id
        )
      end

      def extract_financial_data_from_csv(file, headers, date_format)
        Extractors::Financial::Csv.new(file, headers, date_format).extract!
      end

      def select_file
        opts[:csv_file] || Interactions::SelectFile.new(prompt, 'csv').run!
      end

      def select_source
        opts[:source] || Interactions::SelectSource.new(
          prompt, source_model
        ).run!
      end

      def select_date_format(headers_id)
        opts[:date_format] || Interactions::SelectDateFormat.new(
          header_mapping_model, prompt
        ).run!(
          headers_id
        )
      end

      def select_headers
        opts[:headers] || Interactions::SelectHeaders.new(
          header_mapping_model, prompt
        )
      end

      def detect_new_transactions(transactions)
        print_detect_message
        transactions.each_with_object([]) do |t, new_transactions|
          print '.' unless opts[:quiet]
          next unless transaction_model[
            date: t.date, amount: t.amount, is_debit: t.is_debit
          ].nil?

          new_transactions << t
        end
      end

      def print_detect_message
        return if opts[:quiet]

        puts
        print 'Checking if transactions already present'
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

      def source_model
        @source_model ||= db_proxy.model(:source)
      end

      def category_model
        @category_model ||= db_proxy.model(:category)
      end

      def label_model
        @label_model ||= db_proxy.model(:label)
      end
    end
  end
end
