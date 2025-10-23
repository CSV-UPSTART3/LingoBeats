# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:songs_singers) do
      primary_key [:song_id, :singer_id] # rubocop:disable Style/SymbolArray
      foreign_key :song_id, :songs, key: :id, on_delete: :cascade
      foreign_key :singer_id, :singers, key: :id, on_delete: :cascade

      index [:song_id, :singer_id] # rubocop:disable Style/SymbolArray
    end
  end
end
