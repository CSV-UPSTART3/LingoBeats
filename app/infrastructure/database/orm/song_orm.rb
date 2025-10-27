# frozen_string_literal: true

require 'sequel'

module LingoBeats
  module Database
    # Object-Relational Mapper for Songs
    class SongOrm < Sequel::Model(:songs)
      unrestrict_primary_key

      many_to_many :singers,
                   class: :'LingoBeats::Database::SingerOrm',
                   join_table: :songs_singers,
                   left_key: :song_id, right_key: :singer_id

      one_to_one :lyric,
                 class: :'LingoBeats::Database::LyricOrm',
                 key: :song_id

      plugin :timestamps, update_on_create: true

      def self.find_or_create(song_info)
        first(uri: song_info[:uri]) || create(song_info)
      end
    end
  end
end
