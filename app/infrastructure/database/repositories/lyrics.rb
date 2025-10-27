# frozen_string_literal: true

module LingoBeats
  module Repository
    # Repository for Lyrics
    class Lyrics
      def self.rebuild_entity(db_record)
        return nil if db_record.nil?

        Entity::Lyric.new(
          song_id: db_record[:song_id] || db_record.song_id,
          lyric: db_record[:lyric] || db_record.lyric
        )
      end

      def self.find_by_song_id(song_id)
        db_record = Database::LyricOrm.first(song_id: song_id)
        rebuild_entity(db_record)
      end

      def self.create(entity)
        ds = Database::LyricOrm.dataset # 或 DB[:lyrics]

        ds.insert_conflict(target: :song_id,
                           update: { lyric: Sequel[:excluded][:lyric] })
          .insert(song_id: entity.song_id, lyric: entity.lyric)

        find_by_song_id(entity.song_id)
      end
    end
  end
end
