# frozen_string_literal: true

require 'sequel'

module LingoBeats
  module Database
    # Object-Relational Mapper for Lyric Entities
    class LyricOrm < Sequel::Model(:lyrics)
      unrestrict_primary_key

      # many_to_one :song,
      #             class: :'LingoBeats::Database::SongOrm',
      #             key: :song_id
      one_to_many :songs,
                  class: :'LingoBeats::Database::SongOrm',
                  key: :lyric_id

      plugin :timestamps, update_on_create: true
    end
  end
end
