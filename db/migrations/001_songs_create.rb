# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:songs) do
      String    :id, primary_key: true

      String    :name, null: false
      String    :uri
      String    :external_url

      String    :album_id
      String    :album_name
      String    :album_url
      String    :album_image_url

      DateTime  :created_at
      DateTime  :updated_at
    end
  end
end
