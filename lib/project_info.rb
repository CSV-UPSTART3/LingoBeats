# frozen_string_literal: true

require 'fileutils'
require 'http'
require 'yaml'
require_relative 'http_helper'
require_relative 'spotify_token'
require_relative 'spotify_results_helper'

# --- Spotify API -> Retrieve Songs ---
class SpotifyClient
  def initialize(token_provider: SpotifyToken)
    @token_provider = token_provider
  end

  # search songs through keyword
  def search_tracks(query, **options)
    params = { q: query, type: 'track', market: 'US' }.merge(options)
    fetch_data(api_path('search'), params: params)
  end

  private

  def api_path(path)
    "https://api.spotify.com/v1/#{path}"
  end

  def fetch_data(url, params: {})
    token = @token_provider.access_token
    res = HTTP.headers('Authorization' => "Bearer #{token}")
              .get(url, params: params)
    HttpHelper.parse_json!(res)
  end
end

# --- call spotify api ---
spotify_client = SpotifyClient.new
songs_result = spotify_client.search_tracks('Olivia Rodrigo', limit: 5)

## HAPPY project request
spotify_results = SpotifyTracksResultNormalizer.normalize_results(songs_result)

dir = 'spec/fixtures'
FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
File.write(File.join(dir, 'spotify_results.yml'), spotify_results.to_yaml)
