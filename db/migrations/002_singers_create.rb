# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:singers) do
      String    :id, primary_key: true

      String    :name, null: false
      String    :external_url

      DateTime  :created_at
      DateTime  :updated_at
    end
  end
end
