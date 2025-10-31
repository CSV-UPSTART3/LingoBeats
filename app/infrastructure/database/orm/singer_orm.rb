# frozen_string_literal: true

require 'sequel'

module LingoBeats
  module Database
    # Object Relational Mapper for Singer Entities
    class SingerOrm < Sequel::Model(:singers)
      unrestrict_primary_key # 允許設定主鍵

      many_to_many :songs, # 希望 ORM 幫你產生的方法名稱，會回傳有關 songs 的所有 SongOrm 物件
                   class: :'LingoBeats::Database::SongOrm',
                   join_table: :songs_singers,
                   left_key: :singer_id, right_key: :song_id

      plugin :timestamps, update_on_create: true
    end
  end
end
