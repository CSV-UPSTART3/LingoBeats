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
      cfg = App.config

      @allowed_categories = %w[singer song_name].freeze
      @spotify_mapper = Spotify::SongMapper
                        .new(cfg.SPOTIFY_CLIENT_ID, cfg.SPOTIFY_CLIENT_SECRET)
      @lyric_mapper = Genius::LyricMapper
                      .new(cfg.GENIUS_CLIENT_ACCESS_TOKEN)
    end

    route do |routing|
      routing.assets   # load CSS/JS from assets plugin
      routing.public   # serve /public files
      response['Content-Type'] = 'text/html; charset=utf-8'

      # GET /
      routing.root do
        @current_page = :home
        popular = @spotify_mapper.display_popular_songs

        # load/store lyrics for popular songs
        popular.each do |song_entity|
          GeniusHelper.fetch_lyrics_by_song_id(@lyric_mapper, song_entity.id)
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

      # 子路由
      routing.multi_route
    end

    route('spotify') do |routing|
      # POST /spotify
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

    route('genius') do |routing|
      # GET /genius/search?song_id=xxx&song_name=...&artist_name=...
      routing.on 'search' do
        routing.get do
          song_id = routing.params['song_id']
          song_name = routing.params['song_name']
          artist_name = routing.params['artist_name']
          result = GeniusHelper.fetch_lyrics_by_song_id(@lyric_mapper, song_id, song_name, artist_name)
          return view('lyrics_error', locals: { message: result[:error] }, layout: false) if result.key?(:error)

          view('lyrics_block', locals: { lyrics: result[:lyrics], cached: result[:cached] }, layout: false)
        end
      end
    end

    # ===== Helper methods for Genius flow =====
    module GeniusHelper
      module_function

      def song_repo
        Repository::For.klass(Entity::Song)
      end

      def lyric_repo
        Repository::For.klass(Entity::Lyric)
      end

      def fetch_lyrics_by_song_id(lyric_mapper, song_id = nil, song_name = nil, artist_name = nil)
        song_id = song_id.strip if song_id

        # 1. get from DB
        if song_id && (hit = find_in_db(song_id))
          return hit
        end

        # 2. get from API and cache
        fetch_from_api_and_cache(lyric_mapper, song_id, song_name, artist_name) || { error: 'Lyrics not found' }
      end

      def find_in_db(song_id)
        if (record = lyric_repo.find_by_song_id(song_id))
          { lyrics: record.lyric, cached: true }
        end
      end

      def fetch_from_api_and_cache(lyric_mapper, song_id = nil, song_name = nil, artist_name = nil)
        if (song = song_repo.find_id(song_id))
          song_name   ||= song.name
          artist_name ||= song.singers.first&.name
        end

        lyric_text = lyric_mapper.lyrics_for(song_name: song_name, artist_name: artist_name)

        # write to DB
        write_data_to_db(song_id, lyric_text)

        { lyrics: lyric_text, cached: false }
      end

      def write_data_to_db(song_id, lyric_text)
        # TODO: 要先存歌曲本人
        return unless song_id && !lyric_repo.find_by_song_id(song_id)

        lyric_repo.create(LingoBeats::Entity::Lyric.new(song_id: song_id, lyric: lyric_text))
      end
      private_class_method :find_in_db, :fetch_from_api_and_cache
    end

    # ===== Helper methods for Spotify flow =====
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
