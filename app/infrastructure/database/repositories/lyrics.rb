# frozen_string_literal: true

module LingoBeats
  module Repository
    # Repository for Lyrics
    class Lyrics
      def self.rebuild_entity(db_record)
        return nil unless db_record

        Value::Lyric.new(text: db_record[:text] || db_record.text || nil)
      end

      def self.find_id(id)
        rebuild_entity Database::LyricOrm.first(id: id)
      end

      def self.find_id_by_value(object)
        return nil unless object&.text

        object.checksum
      end

      def self.for_song(song_id)
        song = Database::SongOrm.first(id: song_id)
        return nil unless song

        lyric_id = song[:lyric_id]
        return nil unless lyric_id

        find_id(lyric_id)
      end

      # create lyric and link to song
      def self.find_or_create_by_value(object)
        return nil unless object&.text

        return nil unless object.english?

        id = object.checksum
        ds = Database::LyricOrm.dataset

        # only insert if not exists
        ds.insert_conflict(target: :id).insert(id: id, text: object&.text)
        id
      end

      # attach lyric to song
      def self.attach_to_song(song_id, lyric_object)
        return nil unless song_id && lyric_object&.text
        
        return nil unless lyric_object.english?

        lyric_id = find_or_create_by_value(lyric_object)
        Database::SongOrm.where(id: song_id).update(lyric_id: lyric_id)
        lyric_id
      rescue Sequel::ForeignKeyConstraintViolation, Sequel::NoExistingObject
        nil
      end

      # def self.rebuild_entity_by_lyrics(lyrics)
      #   return nil unless lyrics

      #   id = find_id_by_value(lyrics)
      #   Value::Lyric.new(
      #     text: lyrics
      #   )
      # end

      # def self.find_by_song_id(song_id)
      #   db_record = Database::LyricOrm.first(song_id: song_id)
      #   rebuild_entity(db_record)
      # end

      # def self.create(entity)
      #   ds = Database::LyricOrm.dataset # 或 DB[:lyrics]
      #   song_id = entity.song_id

      #   ds.insert_conflict(target: :song_id,
      #                      update: { lyric: Sequel[:excluded][:lyric] })
      #     .insert(song_id: song_id, lyric: entity.lyric)

      #   find_by_song_id(song_id)
      # rescue Sequel::ForeignKeyConstraintViolation
      #   nil
      # end
    end
  end
end
