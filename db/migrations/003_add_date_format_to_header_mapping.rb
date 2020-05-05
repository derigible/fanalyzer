# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:financial_header_mappings) do
      add_column :date_format, String
    end
  end
end
