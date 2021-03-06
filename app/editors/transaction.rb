# frozen_string_literal: true

require_relative '../interactions/review_transactions'
require_relative '../filters/label'
require_relative '../filters/date'
require_relative '../filters/category'
require_relative '../filters/servicer'

module Editors
  class Transaction
    include Filters::Category
    include Filters::Date
    include Filters::Label
    include Filters::Servicer

    REGEX = /\A[+-]?\d+(\.[\d]+)?\z/.freeze
    PAGE_SIZE = 100

    attr_accessor :proxy, :prompt, :page

    def initialize(db_proxy, tty_prompt)
      @proxy = db_proxy
      @prompt = tty_prompt
      @page = 0
    end

    def run!
      result = prompt.ask(
        'Enter transaction id or leave blank to select a transaction to ' \
        'edit.'
      )

      if result.nil? || result.strip.empty?
        browse
      elsif numeric?(result)
        specific_edit(result)
      else
        puts 'Must provide a valid transaction id.'
        return run!
      end
      continue = prompt.yes?('Edit another transaction?')
      run! if continue
    end

    private

    def specific_edit(result)
      t = transaction_model[result]
      if t.nil?
        puts 'Transaction not found. Please provide a valid transaction id.'
        run!
      end
      edit(t)
    end

    def browse
      models = filtered_models
      transactions = models.limit(PAGE_SIZE, page * PAGE_SIZE).to_a
      result = prompt.select('Select your transaction:', per_page: 15) do |menu|
        transactions.each do |t|
          menu.choice tableize(t), t
        end
        menu_end_choice(transactions, menu)
      end

      handle_browse_result result
    end

    def filtered_models
      models = transaction_model
      if prompt.yes?('Apply filters?')
        models = date_filters(models)
        models = category_filters(models)
        models = servicer_filters(models)
        label_filters(models)
      else
        models
      end
    end

    def tableize(transaction)
      transaction.to_table_row.join(' | ')
    end

    def numeric?(digit)
      !!REGEX.match(digit)
    end

    def menu_end_choice(transactions, menu)
      if transactions.size == PAGE_SIZE
        menu.choice 'See More', :see_more
      else
        menu.choice 'End of list. Start Over.', :start_over
      end
    end

    def handle_browse_result(result)
      if result == :see_more
        self.page += 1
        browse
      elsif result == :start_over
        self.page = 0
        browse
      else
        edit(result)
      end
    end

    def edit(transaction)
      changes = Interactions::ReviewTransactions.new(
        servicer_model,
        category_model,
        label_model,
        transaction_model,
        prompt,
        nil
      ).edit_transaction(transaction.to_struct)
      update_transaction(transaction, changes)
    end

    def update_transaction(transaction, changes)
      changes.labels.each do |label|
        next if label.is_a? OpenStruct

        transaction.add_label(label)
      end
      transaction.update(normalize_changes(changes))
    end

    def normalize_changes(changes)
      changes[:servicer_id] = changes.servicer.id
      changes[:category_id] = changes.category.id
      changes.to_h.except(:id, :servicer, :category, :labels)
    end

    def transaction_model
      @transaction_model ||= proxy.model(:transaction)
    end

    def servicer_model
      @servicer_model ||= proxy.model(:servicer)
    end

    def category_model
      @category_model ||= proxy.model(:category)
    end

    def label_model
      @label_model ||= proxy.model(:label)
    end
  end
end
