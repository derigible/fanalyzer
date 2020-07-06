# frozen_string_literal: true

require 'active_support/core_ext/object/blank'

module Interactions
  class RemoveLabel
    attr_reader(
      :prompt,
      :transaction_model,
      :label_model,
      :transaction
    )

    def initialize(
      transaction,
      transaction_model,
      label_model,
      tty_prompt
    )
      @transaction = transaction
      @transaction_model = transaction_model
      @label_model = label_model
      @prompt = tty_prompt
    end

    def run!
      to_remove = prompt.select(
        'Choose label to remove (leave blank to cancel',
        filter: true
      ) do |menu|
        transaction.labels.each do |l|
          menu.choice l.name, l
        end
        menu.choice 'None', :edit_different
      end
      return :edit_different if to_remove == :edit_different

      remove_label(transaction, to_remove)
    end

    private

    def remove_label(transaction, to_remove)
      if transaction.is_a?(OpenStruct) && !transaction.id.blank?
        t = transaction_model[transaction.id]
        l = label_model[to_remove.id]
        t.remove_label(l)
      end
      transaction.labels = transaction.labels.filter do |label|
        label != to_remove
      end
    end
  end
end
