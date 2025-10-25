# frozen_string_literal: true

module LingoBeats
  module Repository
    # Repository for Lyrics
    class Lyrics
      def self.rebuild_entity(db_record)
        return nil unless db_record

        db_record = db_record.first if db_record.is_a?(Array)

        Entity::Lyric.new(
          id: db_record.song_id,
          lyric: db_record.lyric
        )
      end
    end
  end
end
