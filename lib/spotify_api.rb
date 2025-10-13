# frozen_string_literal: true

require 'fileutils'
require 'http'
require 'yaml'
require_relative 'spotify_token'
require_relative 'spotify_track_normalizer'

module LingoBeats
  # --- Spotify API -> Retrieve Songs ---
  class SpotifyClient
    BASE_PATH = 'https://api.spotify.com/v1/'

    def initialize(token_provider = SpotifyToken)
      @spotify_token = token_provider.access_token
    end

    # search songs by artist name
    def search_songs_by_artist(artist_name)
      search_songs(category: :artist, query: artist_name, limit: 3)
    end

    # search song by song name
    def search_song_by_name(song_name)
      search_songs(category: :song_name, query: song_name, limit: 1)
    end

    # search songs with specified condition
    def search_songs(category:, query:, **options)
      spec = SearchSpec.new(category: category, query: query, options: options)
      results = HttpHelper::Request.new('Authorization' => "Bearer #{@spotify_token}")
                                   .get(spotify_search_url('search'), params: spec.params)
      SpotifyTrackNormalizer.normalize_results(results)
    end

    private

    def spotify_search_url(method)
      "#{BASE_PATH}#{method}"
    end

    # ---- nested class (internal) ----
    # Function for search preparation and validation
    class SearchSpec
      QUERY_BY_CATEGORY = { artist: 'artist', song_name: 'track' }.freeze

      def initialize(category:, query:, options: {})
        @category = category.is_a?(Symbol) ? category : category.downcase.to_sym
        @query = query
        @options = options

        check_category
        check_query
      end

      def check_category
        return true if QUERY_BY_CATEGORY.key?(@category)

        raise ArgumentError, "Unsupported search type: #{@category.inspect}"
      end

      def check_query
        return true unless @query.to_s.strip.empty?

        raise ArgumentError, 'Query cannot be blank'
      end

      def params
        {
          type: 'track',
          market: 'US',
          q: %(#{QUERY_BY_CATEGORY[@category]}:"#{@query}")
        }.merge(@options)
      end
    end

    private_constant :SearchSpec
  end
end
