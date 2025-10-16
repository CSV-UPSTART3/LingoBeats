# frozen_string_literal: true

require 'uri'
require 'roda'
require 'slim'

module LingoBeats
  # Web App
  class App < Roda
    plugin :render, engine: 'slim', views: 'app/views'
    plugin :assets, css: 'style.css', path: 'app/views/assets'
    plugin :common_logger, $stderr
    plugin :halt

    route do |routing|
      routing.assets # load CSS
      response['Content-Type'] = 'text/html; charset=utf-8'

      # GET /
      routing.root do
        view 'home'
      end

      routing.on 'spotify' do
        routing.is do
          # POST /spotify/
          routing.post do
            query = routing.params['query']
            category = routing.params['category']&.to_sym # :song_name or :artist
            routing.halt 400 if query.nil? || query.strip.empty?
            routing.halt 400 unless %i[song_name artist].include?(category)
            # puts query
            # encoded_query = URI.encode_www_form_component(query)
            # puts encoded_query
            routing.redirect "spotify/#{category}/#{query}" # e.g. /spotify/artist/Taylor%20Swift
          end
        end

        # GET /spotify/[category]/[query]
        routing.on String, String do |category_str, query|
          routing.get do
            query = query.tr('+', ' ')
            category = category_str.to_sym
            spotify_mapper = LingoBeats::Spotify::SongMapper
                             .new(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET)

            spotify_songs =
              if category == :artist
                spotify_mapper.search_songs_by_singer(query)
              else
                spotify_mapper.search_songs_by_name(query)
              end

            view 'project', locals: { songs: spotify_songs, category:, query: }
          end
        end
      end
    end
  end
end
