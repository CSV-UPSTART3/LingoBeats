# frozen_string_literal: true

require 'uri'
require 'roda'
require 'slim'

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
      @query = ''
      @category = ''
      @spotify_mapper = LingoBeats::Spotify::SongMapper
                        .new(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET)
    end

    route do |routing|
      routing.assets # load CSS
      response['Content-Type'] = 'text/html; charset=utf-8'

      # GET /
      routing.root { view 'home' }

      routing.multi_route

      # routing.on 'spotify' do
      #   spotify_run(routing)
      # end
    end

    route('spotify') do |routing|
      routing.is { routing.post { spotify_post(routing) } }

      routing.on String, String do |category_str, raw_query|
        @category = category_str.to_sym
        @query    = raw_query.tr('+', ' ')
        spotify_get(routing)
      end
    end

    private

    # def spotify_run(routing)
    #   routing.is do
    #     # POST /spotify/
    #     routing.post { spotify_post(routing) }
    #   end
    #   # GET /spotify/[category]/[query]
    #   routing.on String, String do |category_str, query|
    #     @query = query.tr('+', ' ')
    #     @category = category_str.to_sym
    #     spotify_get(routing)
    #   end
    # end

    def spotify_post(routing)
      params = routing.params
      @query = params['query'].to_s
      @category = params['category']&.to_sym # :song_name or :artist
      request.halt(400) if @query.strip.empty? || !%i[song_name singer].include?(@category)
      # puts query
      # encoded_query = URI.encode_www_form_component(query)
      # puts encoded_query
      request.redirect "spotify/#{@category}/#{@query}" # e.g. /spotify/artist/Taylor%20Swift
    end

    def spotify_get(routing)
      routing.get do
        spotify_songs =
          if @category == :singer
            @spotify_mapper.search_songs_by_singer(@query)
          else
            @spotify_mapper.search_songs_by_name(@query)
          end
        view 'project', locals: { songs: spotify_songs, category: @category, query: @query }
      end
    end
  end
end
