# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:sources) do
      primary_key :id
      String :name, text: true
    end

    create_table(:uploads) do
      primary_key :id
      Timestamp :timestamp
      foreign_key :source_id, :sources, on_delete: :cascade, null: true
    end

    create_table(:servicers) do
      primary_key :id
      String :name, text: true
      foreign_key :servicer_id, :servicers, on_delete: :cascade, null: true
      foreign_key :upload_id, :uploads, on_delete: :cascade, null: true
    end

    create_table(:categories) do
      primary_key :id
      String :name, text: true
      foreign_key :category_id, :categories, on_delete: :cascade, null: true
      foreign_key :upload_id, :uploads, on_delete: :cascade, null: true
    end

    create_table(:transactions) do
      primary_key :id
      Date :date
      String :description, text: true
      Float :amount
      TrueClass :is_debit
      foreign_key :category_id, :categories, on_delete: :set_null, null: true
      foreign_key :servicer_id, :servicers, on_delete: :set_null, null: true
      foreign_key :upload_id, :uploads, on_delete: :set_null, null: true
    end

    create_table(:financial_header_mappings) do
      primary_key :id
      String :name, text: true
      String :date, text: true
      String :description, text: true
      String :amount, text: true
      String :type, text: true
      String :servicer, text: true
      String :category, text: true
      String :date_format, text: true
    end
  end
end
