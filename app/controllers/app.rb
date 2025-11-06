# frozen_string_literal: true

require 'uri'
require 'roda'
require 'slim'
require 'rack'
require 'rack/utils'
require 'slim/include'

require_relative '../presentation/views_object/songs_list'

# LingoBeats: include routing and service
module LingoBeats
  # Web App
  class App < Roda
    plugin :flash
    plugin :all_verbs # allows HTTP verbs beyond GET/POST (e.g., DELETE)
    plugin :render, engine: 'slim', views: 'app/presentation/views_html'
    plugin :public, root: 'app/presentation/public'
    plugin :assets, path: 'app/presentation/assets',
                    css: 'style.css', js: 'main.js'
    plugin :common_logger, $stderr
    plugin :halt
    plugin :multi_route

    use Rack::MethodOverride # allows HTTP verbs beyond GET/POST (e.g., DELETE)

    ALLOWED_CATEGORIES = %w[singer song_name].freeze
    MESSAGES = {
      invalid_query: 'Invalid search query',
      search_failed: 'Error in searching songs',
      no_songs_found: 'No songs found for the given query'
    }.freeze

    def initialize(*)
      super
      cfg = App.config
      @spotify_mapper = Spotify::SongMapper
                        .new(cfg.SPOTIFY_CLIENT_ID, cfg.SPOTIFY_CLIENT_SECRET)
    end

    route do |routing| # rubocop:disable Metrics/BlockLength
      routing.assets   # load CSS/JS from assets plugin
      routing.public   # serve /public files
      response['Content-Type'] = 'text/html; charset=utf-8'

      # GET /
      routing.root do
        @current_page = :home
        # Get cookie viewer's previously seen songs
        watching = session[:watching] || {}
        # puts "Watching: #{watching.inspect}"

        # check if internal navigation
        referer = request.referer
        is_internal_navigation = referer&.start_with?(request.base_url)

        if watching.empty? || is_internal_navigation
          popular = @spotify_mapper.display_popular_songs

          session[:watching] = {
            category: 'song_name',
            query: '',
            song_ids: popular.map(&:id)
          }

          view 'home', locals: { popular: popular }
        else
          songs = Array(watching[:song_ids]).map do |id|
            @spotify_mapper.fetch_song_info_by_id(id)
          end.compact
          prev_search_results = Views::SongsList.new(songs)
          view 'song', locals: { songs: prev_search_results, category: watching[:category], query: watching[:query] }
        end
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

    route('songs') do |routing|
      # POST /songs
      routing.is do
        routing.post do
          category, query = SpotifyHelper.get_params(routing)

          unless ALLOWED_CATEGORIES.include?(category) && query.to_s.strip.length.positive?
            flash[:error] = MESSAGES[:invalid_query]
            response.status = 400
            routing.redirect '/'
          end

          routing.redirect SpotifyHelper.search_path(category, query)
        end
      end

      # GET /songs/search?category=...&query=...
      routing.on 'search' do
        routing.get do
          category, query = SpotifyHelper.get_params(routing)
          songs = @spotify_mapper.public_send("search_songs_by_#{category}", query)
          # flash.now[:error] = MESSAGES[:no_songs_found] if songs.empty? # 試效果

          session[:watching] = {
            category: category,
            query: query,
            song_ids: songs.map(&:id)
          }

          view 'song', locals: { songs:, category:, query: }
        end
      end
    end

    route('lyrics') do |routing|
      # GET /lyrics/song?id=...&name=...&singer=...
      routing.on 'song' do
        routing.get do
          song_id, song_name, singer_name = GeniusHelper.get_params(routing)
          song_id = song_id.to_s.strip

          if song_id.empty?
            flash[:error] = MESSAGES[:invalid_query]
            response.status = 400
            routing.redirect '/'
          end

          # ensure song/singer existed in DB
          Repository::For.klass(Entity::Song).ensure_song_exists(song_id)

          # fetch lyrics (from DB or API)
          result = GeniusHelper.fetch_lyrics(song_id, song_name, singer_name)
          view 'lyrics_block', locals: { lyrics: result[:lyrics], cached: result[:cached] }, layout: false
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
        req.params.values_at('id', 'name', 'singer').map(&:to_s)
      end

      def fetch_lyrics(song_id, song_name = nil, singer_name = nil)
        # 1. get from DB
        if (hit = find_in_db(song_id))
          return hit
        end

        # 2. call api if not found in DB
        fetch_from_api_and_cache(song_id, song_name, singer_name)
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
        "/songs/search?#{qs}"
      end
    end
  end
end
