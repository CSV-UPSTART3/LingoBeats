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
      @spotify_mapper = Spotify::SongMapper
                        .new(cfg.SPOTIFY_CLIENT_ID, cfg.SPOTIFY_CLIENT_SECRET)
    end

    route do |routing|
      routing.assets   # load CSS/JS from assets plugin
      routing.public   # serve /public files
      response['Content-Type'] = 'text/html; charset=utf-8'

      # GET /
      routing.root do
        @current_page = :home
        popular = @spotify_mapper.display_popular_songs
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
          # TODO: store song data first with session

          song_id, song_name, artist_name = GeniusHelper.get_params(routing)
          result = GeniusHelper.fetch_lyrics(song_id, song_name, artist_name)
          view('lyrics_block', locals: { lyrics: result[:lyrics], cached: result[:cached] }, layout: false)
        end
      end
    end

    # ===== Helper methods for Genius flow =====
    module GeniusHelper
      module_function

      def lyric_mapper = Genius::LyricMapper.new(App.config.GENIUS_CLIENT_ACCESS_TOKEN)
      def lyric_repo   = Repository::For.klass(Value::Lyric)
      def song_repo    = Repository::For.klass(Entity::Song)

      def get_params(req)
        req.params.values_at('song_id', 'song_name', 'artist_name').map(&:to_s)
      end

      def fetch_lyrics(song_id, song_name = nil, artist_name = nil)
        sid = song_id.to_s.strip
        return { error: 'missing song_id' } if sid.empty?

        # 1. get from DB
        if (hit = find_in_db(sid))
          return hit
        end

        # 2. call api if not found in DB
        fetch_from_api_and_cache(sid, song_name, artist_name)
      end

      # --- internals ---
      def find_in_db(song_id)
        vo = lyric_repo.for_song(song_id)
        text = vo&.text.to_s.strip
        return unless text.length.positive?

        { lyrics: text, cached: true }
      end

      def fetch_from_api_and_cache(song_id, song_name, artist_name)
        text = lyric_mapper.lyrics_for(song_name: song_name, artist_name: artist_name).to_s
        return { error: 'Lyrics not found' } if text.strip.empty?

        persist_lyrics(song_id, text) if song_repo.find_id(song_id)
        { lyrics: text, cached: false }
      end

      def persist_lyrics(song_id, text)
        lyric_repo.attach_to_song(song_id, Value::Lyric.new(text: text))
      end
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
