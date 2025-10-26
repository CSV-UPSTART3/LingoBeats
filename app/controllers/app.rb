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
    plugin :assets, css: 'style.css', path: 'app/views/assets'
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
      response['Content-Type'] = 'text/html; charset=utf-8'

      # GET /
      # routing.root { view 'home' }
      routing.root do
        popular = @spotify_mapper.display_popular_songs
        view 'home', locals: { popular: popular }
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
          view 'project', locals: { songs: songs, category: category, query: query }
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
