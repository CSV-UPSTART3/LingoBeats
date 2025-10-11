# frozen_string_literal: true

require 'fileutils'
require 'http'
require 'yaml'
require_relative 'spotify_token'
require_relative 'http_helper'
require_relative 'spotify_results_helper'

module LingoBeats

  # --- Spotify API -> Retrieve Songs ---
  class SpotifyClient
    def initialize(token_provider: SpotifyToken)
      @token_provider = token_provider
    end

    # search songs through artist
    def search_songs_by_artist(query, **options)
      params = { q: "artist:\"#{query}\"", type: 'track', market: 'US' }.merge(options)
      LingoBeats::SpotifyTracksResultNormalizer.normalize_results(fetch_data(api_path('search'), params: params)) 
    end

    # search a song through song_name
    def search_song_by_name(song_name, **options)
      params = { q: "track:\"#{song_name}\"", type: 'track', market: 'US', limit: 1 }.merge(options)
      LingoBeats::SpotifyTracksResultNormalizer.normalize_results(fetch_data(api_path('search'), params: params))
    end

    private

    def api_path(path)
      "https://api.spotify.com/v1/#{path}"
    end

    def fetch_data(url, params: {})
      token = @token_provider.access_token
      res = HTTP.headers('Authorization' => "Bearer #{token}")
                .get(url, params: params)
      LingoBeats::HttpHelper.parse_json!(res)
    end
  end
end
