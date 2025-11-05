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
      @song_repo = Repository::For.klass(Entity::Song)
      @lyric_repo = Repository::For.klass(Value::Lyric)
    end

    route do |routing|
      routing.assets   # load CSS/JS from assets plugin
      routing.public   # serve /public files
      response['Content-Type'] = 'text/html; charset=utf-8'

      # GET /
      routing.root do
        @current_page = :home
        popular = @spotify_mapper.display_popular_songs

        # # load/store lyrics for popular songs
        # genius = GeniusHelper.new(lyric_mapper: @lyric_mapper, song_repo: @song_repo, lyric_repo: @lyric_repo)
        # popular.each do |song_entity|
        #   genius.fetch_lyrics(song_entity.id)
        # end

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

          genius = GeniusHelper.new(lyric_mapper: @lyric_mapper, song_repo: @song_repo, lyric_repo: @lyric_repo)
          song_id, song_name, artist_name = genius.get_params(routing)
          result = genius.fetch_lyrics(song_id, song_name, artist_name)
          view('lyrics_block', locals: { lyrics: result[:lyrics], cached: result[:cached] }, layout: false)
        end
      end
    end

    # ===== Helper methods for Genius flow =====
    class GeniusHelper
      def initialize(lyric_mapper:, song_repo:, lyric_repo:)
        @lyric_mapper = lyric_mapper
        @song_repo = song_repo
        @lyric_repo = lyric_repo
      end

      def get_params(req)
        req.params.values_at('song_id', 'song_name', 'artist_name').map(&:to_s)
      end

      def fetch_lyrics(song_id, song_name = nil, artist_name = nil)
        song_id = song_id.to_s.strip
        return { error: 'missing song_id' } if song_id.empty?

        # 1. get from DB
        if (hit = find_in_db(song_id))
          return hit
        end

        # 2. call API if not in DB
        fetch_from_api_and_cache(song_id, song_name, artist_name) || { error: 'Lyrics not found' }
      end

      private

      def find_in_db(song_id)
        vo = @lyric_repo.for_song(song_id)
        return unless vo && !vo.text.to_s.strip.empty?

        { lyrics: vo.text, cached: true }
      end

      def fetch_from_api_and_cache(song_id, song_name, artist_name)
        if (song = @song_repo.find_id(song_id))
          song_name   ||= song.name
          artist_name ||= song.singers.first&.name
        end

        lyric_text = @lyric_mapper.lyrics_for(song_name: song_name, artist_name: artist_name)

        vo = Value::Lyric.new(text: lyric_text)
        lyric_id = @lyric_repo.attach_to_song(song_id, vo)
        { lyrics: lyric_text, cached: false } if lyric_id
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
