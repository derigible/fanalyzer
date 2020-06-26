# frozen_string_literal: true

require_relative 'select_headers'
require_relative 'new_servicer'
require_relative 'new_category'

module Interactions
  class ReviewTransactions
    attr_reader(
      :prompt, :servicer_model, :transactions, :category_model, :upload_id
    )

    def initialize(
      transactions, servicer_model, category_model, tty_prompt, upload_id
    )
      @transactions = transactions
      @servicer_model = servicer_model
      @prompt = tty_prompt
      @category_model = category_model
      @upload_id = upload_id
    end

    def run!; end

    private

    def review_transaction(transaction)
      table = TTY::Table.new(transaction.keys, transaction.values)
      puts table.render(:ascii)
      choice = prompt.select(
        'Select action'
      ) do |menu|
        menu.choice 'Next Transaction', :save
        SelectHeaders::CHOICES.each do |field|
          menu.choice("Edit #{field}", field.to_sym)
        end
      end

      edit(transaction, choice)
    end

    def edit(transaction, choice)
      return edit_servicer(transaction) if choice == :servicer
      return edit_category(transaction) if choice == :category

      change = prompt.ask(
        'What should the new value be? (Leave blank to cancel edit)'
      )

      return review_transaction(transaction) if change.empty?

      transaction[choice] = change
    end

    def edit_servicer(transaction)
      result = NewServicer.new(
        transaction.servicer, servicer_model, prompt, upload_id
      ).transaction_edit!
      review_transaction(transaction) if result == :edit_different
    end

    def edit_category(transaction)
      result = NewCategory.new(
        transaction.category, category_model, prompt, upload_id
      ).transaction_edit!

      review_transaction(transaction) if result == :edit_different
    end
  end
end
