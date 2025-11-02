# frozen_string_literal: true

require 'uri'
require 'roda'
require 'slim'
require 'rack/utils'

# LingoBeats: include routing and service
module LingoBeats
  # Web App
  class App < Roda
    plugin :render, engine: 'slim', views: 'app/views'
    plugin :public, root: 'app/views/public'
    plugin :assets, path: 'app/views/assets',
                    css: 'style.css', js: 'main.js'
    plugin :common_logger, $stderr
    plugin :halt
    plugin :multi_route

    def initialize(*)
      super
      @allowed_categories = %w[singer song_name].freeze
      @spotify_mapper = LingoBeats::Spotify::SongMapper
                        .new(App.config.SPOTIFY_CLIENT_ID, App.config.SPOTIFY_CLIENT_SECRET)

      @lyric_mapper = LingoBeats::Genius::LyricMapper
                      .new(App.config.GENIUS_CLIENT_ACCESS_TOKEN)
    end

    route do |routing|
      routing.assets # load CSS
      routing.public # load public assets
      response['Content-Type'] = 'text/html; charset=utf-8'

      # GET /
      # routing.root { view 'home' }
      routing.root do
        @current_page = :home
        popular = @spotify_mapper.display_popular_songs

        song_repo = LingoBeats::Repository::For.klass(LingoBeats::Entity::Song)
        lyric_repo = LingoBeats::Repository::For.klass(LingoBeats::Entity::Lyric)

        popular.each do |song_entity|
          db_song_entity = song_repo.find_id(song_entity.id)
          existing_lyric = lyric_repo.find_by_song_id(song_entity.id)

          # if song already exists in DB
          if db_song_entity
            # 歌已經存在了
            # 如果它還沒有歌詞 -> 試著補歌詞
            if existing_lyric.nil?
              first_singer_name = song_entity.singers.first&.name
              lyric_text = @lyric_mapper.lyrics_for(
                song_name: song_entity.name,
                artist_name: first_singer_name
              )

              if lyric_text
                lyric_entity = LingoBeats::Entity::Lyric.new(
                  song_id: song_entity.id,
                  lyric: lyric_text
                )
                lyric_repo.create(lyric_entity)
              end
            end

            next
          end

          # if song does not exist in DB
          # 先把歌（跟歌手關聯）寫進 songs 資料表
          song_repo.create(song_entity)

          # 再去拿歌詞，然後再存入 lyrics
          first_singer_name = song_entity.singers.first&.name
          lyric_text = @lyric_mapper.lyrics_for(
            song_name: song_entity.name,
            artist_name: first_singer_name
          )

          next unless lyric_text

          lyric_entity = LingoBeats::Entity::Lyric.new(
            song_id: song_entity.id,
            lyric: lyric_text
          )
          lyric_repo.create(lyric_entity)
        end

        view 'home', locals: { popular: popular }
      end

      # GET /tutorial
      routing.on 'tutorial' do
        @current_page = :tutorial
        view 'tutorial'
      end

      # GET /history
      routing.on 'history' do
        @current_page = :history
        view 'history'
      end

      # sub route for spotify
      routing.multi_route
    end

    route('spotify') do |routing|
      # Post /spotify
      routing.is do
        routing.post do
          category, query = SpotifyHelper.get_params(routing)
          routing.redirect SpotifyHelper.search_path(category, query)
        end
      end

      # GET /spotify/search?category=...&query=...
      routing.on 'search' do
        routing.get do
          category, query = SpotifyHelper.get_params(routing)
          songs = @spotify_mapper.public_send("search_songs_by_#{category}", query)
          view 'song', locals: { songs: songs, category: category, query: query }
        end
      end
    end

    # Helper methods for Spotify flow
    module SpotifyHelper
      module_function

      def get_params(req)
        req.params.values_at('category', 'query').map(&:to_s)
      end

      def search_path(category, query)
        qs = Rack::Utils.build_query('category' => category, 'query' => query)
        "/spotify/search?#{qs}"
      end
    end
  end
end
