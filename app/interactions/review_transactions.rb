# frozen_string_literal: true

require_relative 'select_headers'
require_relative 'new_servicer'
require_relative 'new_category'
require_relative 'new_label'
require 'active_support/core_ext/object/blank'

module Interactions
  class ReviewTransactions
    attr_reader(
      :prompt,
      :servicer_model,
      :transactions,
      :category_model,
      :label_model,
      :upload_id
    )

    def initialize(
      servicer_model,
      category_model,
      label_model,
      tty_prompt,
      upload_id,
      transactions = []
    )
      @transactions = transactions
      @servicer_model = servicer_model
      @prompt = tty_prompt
      @category_model = category_model
      @label_model = label_model
      @upload_id = upload_id
    end

    def run!
      save_and_exit = false
      results = transactions.map do |t|
        next if save_and_exit

        result = review_transaction(t)
        save_and_exit = result == :save_edited
        next if save_and_exit

        result
      end.compact
      results
    end

    def edit_transaction(transaction)
      print_transaction(transaction)
      choice = prompt.select(
        'Select action',
        enum: '.'
      ) do |menu|
        menu.choice 'Save', :save
        menu.choice 'Add Label', :add_label
        menu.choice 'Remove Label', :remove_label
        (SelectHeaders::CHOICES - ['date']).each do |field|
          menu.choice("Edit #{field}", field.to_sym)
        end
      end

      return transaction if choice == :save

      edit(transaction, choice)
      save?(transaction)
    end

    private

    def review_transaction(transaction)
      print_transaction(transaction)
      choice = prompt.select(
        'Select action',
        enum: '.'
      ) do |menu|
        menu.choice 'Next Transaction', :save
        menu.choice 'Save Reviewed and Exit', :save_edited
        menu.choice 'Add Label', :add_label
        menu.choice 'Remove Label', :remove_label
        (SelectHeaders::CHOICES - ['date']).each do |field|
          menu.choice("Edit #{field}", field.to_sym)
        end
      end

      return transaction if choice == :save
      return choice if choice == :save_edited

      edit(transaction, choice)
      save?(transaction)
    end

    def normalize_transaction(transaction)
      t = transaction.to_h.except(:date_format, :is_debit)
      t[:servicer] = transaction.servicer.name
      t[:category] = transaction.category.name
      t[:type] = transaction.is_debit ? 'debit' : 'credit'
      t
    end

    def edit(transaction, choice)
      return edit_servicer(transaction) if choice == :servicer
      return edit_category(transaction) if choice == :category
      return edit_type(transaction) if choice == :type
      return add_label(transaction) if choice == :add_label
      return remove_label(transaction) if choice == :remove_label

      edit_field(transction, choice)
    end

    def edit_field(transaction, choice)
      change = prompt.ask(
        'What should the new value be? (Leave blank to cancel edit)'
      )

      return review_transaction(transaction) if change.blank?

      transaction[choice] = change
      transaction
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

    def edit_type(transaction)
      transaction.is_debit = !transaction.is_debit
    end

    def save?(transaction)
      puts
      puts 'Updated transaction'
      print_transaction(transaction)
      result = prompt.yes?('Continue editing transaction?')
      result ? review_transaction(transaction) : transaction
    end

    def print_transaction(transaction)
      normalized_transaction = normalize_transaction(transaction)
      table = TTY::Table.new(
        normalized_transaction.keys, [normalized_transaction.values]
      )
      puts table.render(:ascii)
    end

    def add_label(transaction)
      result = NewLabel.new(
        label_model, prompt, transaction
      ).run!

      review_transaction(transaction) if result == :edit_different
    end

    def remove_label; end
  end
end
