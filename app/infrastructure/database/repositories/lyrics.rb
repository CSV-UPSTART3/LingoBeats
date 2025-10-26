# frozen_string_literal: true

module LingoBeats
  module Repository
    # Repository for Lyrics
    class Lyrics
      def self.rebuild_entity(db_record)
        return nil if db_record.nil? || db_record.respond_to?(:empty?) && db_record.empty?

        db_record = db_record.first if db_record.is_a?(Array)

        Entity::Lyric.new(
          song_id: db_record.song_id,
          lyric: db_record.lyric
        )
      end

      def self.find_by_song_id(song_id)
        db_record = Database::LyricOrm.first(song_id: song_id)
        rebuild_entity(db_record)
      end

      def self.create(entity)
        Database::LyricOrm.create(
          song_id: entity.song_id,
          lyric: entity.lyric
        )
      end
    end
  end
end
