# frozen_string_literal: true

require 'active_support/core_ext/object/blank'

module Interactions
  class NewLabel
    attr_reader(:prompt, :label_model, :transaction)

    def initialize(label_model, tty_prompt, transaction)
      @transaction = transaction
      @prompt = tty_prompt
      @label_model = label_model
    end

    def run!
      add_label(transaction)
    end

    private

    def add_label(transaction)
      action = prompt.select(
        'Select how to add label (select None to cancel):'
      ) do |menu|
        menu.choice 'Create new', :create_label
        menu.choice 'Attach existing', :attach_label
        menu.choice 'None', :edit_different
      end
      return action if action == :edit_different

      send(action, transaction)
    end

    def find_label
      labels = label_model
      prompt.select(
        'Select label to add (type to search)', filter: true
      ) do |menu|
        labels.each do |l|
          menu.choice l.name, l
        end
        menu.choice 'None', :none
      end
    end

    def create_label(transaction)
      use = prompt.ask(
        'Enter labels name (leave blank to do a different option)'
      )
      return add_label(transaction) if use.blank?

      unless label_model[name: use].nil?
        puts("Label #{use} already exists.")
        return create_label(transaction)
      end

      label = label_model.create(name: use)
      append_label(transaction, label)
    end

    def attach_label(transaction)
      label = find_label
      return add_label(transaction) if label == :none

      append_label(transaction, label)
    end

    def append_label(transaction, label)
      transaction.label ||= []
      transaction.label << label
    end
  end
end
