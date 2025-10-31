# frozen_string_literal: true

require_relative 'singers'
require_relative '../../spotify/mappers/song_mapper' # for SongMapper
# require_relative '../genius/mappers/lyric_mapper'       # (可能之後用)
require_relative '../../../controllers/app' # so App.config is loaded

module LingoBeats
  module Repository
    # Repository for Song Entities
    class Songs
      def self.find_or_create(song_info)
        orm = LingoBeats::Database::SongOrm
        orm.first(uri: song_info[:uri]) || orm.create(song_info)
      end

      def self.all
        rows = Database::SongOrm.all
        return rebuild_many(rows) unless rows.empty?

        seed_from_spotify
        # rebuild_many(Database::SongOrm.all)
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

      def self.create(entity)
        raise 'Song already exists' if find_id(entity.id)

        # return find_id(entity.id) if find_id(entity.id)
        db_song = PersistSong.new(entity).call
        rebuild_entity(db_song)
      end

      def self.seed_from_spotify
        # 初始化 mapper
        mapper = build_spotify_mapper

        # 從 Spotify 抓熱門歌:回來是一個 [Entity::Song, ...]
        songs_from_api = mapper.display_popular_songs

        # 把每一首歌存進 DB（含 singers/lyric(nil)）
        songs_from_api.each do |song_entity|
          create(song_entity)
        end

        songs_from_api
      end

      def self.build_spotify_mapper
        config = LingoBeats::App.config
        LingoBeats::Spotify::SongMapper.new(
          config.SPOTIFY_CLIENT_ID,
          config.SPOTIFY_CLIENT_SECRET
        )
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

          # 建立歌手關聯
          @entity.singers.each do |singer|
            db_singer = LingoBeats::Repository::Singers.find_or_create(singer.to_attr_hash)
            db_song.add_singer(db_singer) unless db_song.singers.include?(db_singer)
          end

          db_song
        end
      end
    end
  end
end
