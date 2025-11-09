# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:materials) do
      primary_key :id
      String   :song_id,   null: false
      String   :level,     null: false
      Text     :content,   null: false # 存 JSON 字串
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :song_id
      index :level
    end
  end
end
