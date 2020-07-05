# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:labels) do
      primary_key :id
      String :name, text: true
    end

    create_table(:labels_transactions) do
      primary_key :id
      foreign_key :label_id, :labels, on_delete: :cascade, null: true
      foreign_key(
        :transaction_id, :transactions, on_delete: :cascade, null: true
      )
    end
  end
end
