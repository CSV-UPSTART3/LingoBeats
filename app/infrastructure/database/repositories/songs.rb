# frozen_string_literal: true

require_relative 'singers'

module LingoBeats
  module Repository
    # Repository for Song Entities
    class Songs
      def self.all
        rebuild_many(Database::SongOrm.all)
      end

      def self.rebuild_many(db_records)
        db_records.map { |record| rebuild_entity(record) }
      end

      def self.find_id(id)
        db_record = Database::SongOrm.first(id: id)
        rebuild_entity(db_record)
      end

      def self.find_name(name)
        db_record = Database::SongOrm.first(name: name)
        rebuild_entity(db_record)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Song.new(
          id: db_record.id,
          name: db_record.name,
          uri: db_record.uri,
          external_url: db_record.external_url,
          album_id: db_record.album_id,
          album_name: db_record.album_name,
          album_url: db_record.album_url,
          album_image_url: db_record.album_image_url,
          # 一對一：歌詞
          lyric: Lyrics.rebuild_entity(db_record.lyric),
          # 多對多：歌手
          singers: Singers.rebuild_many(db_record.singers)
        )
      end

      def self.db_find_or_create(entity)
        Database::SongOrm.find_or_create(entity.to_attr_hash)
      end

      def self.create(entity)
        raise 'Song already exists' if find_id(entity.id)

        db_song = PersistSong.new(entity).call
        rebuild_entity(db_song)
      end

      # helper class to persist song, lyric, singers
      class PersistSong
        def initialize(entity)
          @entity = entity
        end

        def create_song
          Database::SongOrm.create(@entity.to_attr_hash)
        end

        def call
          db_song = create_song

          # 建立歌詞（若存在）
          if @entity.lyric
            db_song.add_lyric(
              Database::LyricOrm.create(
                song_id: db_song.id,
                lyric: @entity.lyric.lyric
              )
            )
          end

          # 建立歌手關聯
          @entity.singers.each do |singer|
            db_singer = Singers.db_find_or_create(singer)
            db_song.add_singer(db_singer) unless db_song.singers.include?(db_singer)
          end

          db_song
        end
      end
    end
  end
end
