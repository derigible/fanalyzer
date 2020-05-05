# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:financial_header_mappings) do
      primary_key :id
      String :name, text: true
      String :date, text: true
      String :description, text: true
      String :amount, text: true
      String :type, text: true
      String :servicer, text: true
      String :category, text: true
    end
  end
end
