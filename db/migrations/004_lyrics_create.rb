# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:lyrics) do
      String :song_id, primary_key: true
      foreign_key [:song_id], :songs, key: :id, on_delete: :cascade

      String :lyric
    end
  end
end
