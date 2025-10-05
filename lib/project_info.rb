# frozen_string_literal: true

require 'fileutils'
require 'http'
require 'yaml'
require_relative 'http_helper'
require_relative 'spotify_token'
require_relative 'spotify_results_helper'

# --- Spotify API -> Retrieve Songs ---
def spotify_api_path(path)
  "https://api.spotify.com/v1/#{path}"
end

def fetch_spotify_data(url, params: {})
  token = SpotifyToken.access_token
  headers = { 'Authorization' => "Bearer #{token}" }
  res = HTTP.headers(headers).get(url, params: params)
  HttpHelper.parse_json!(res)
end

def search_songs_via_spotify(query, **options)
  params = { q: query, type: 'track', markets: 'US' }.merge(options)
  fetch_spotify_data(spotify_api_path('search'), params: params)
end

# --- call spotify api ---
songs_result = search_songs_via_spotify('Olivia Rodrigo', limit: 5)

## HAPPY project request
spotify_results = SpotifyTracksResultNormalizer.normalize_results(songs_result)

dir = 'spec/fixtures'
FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
File.write(File.join(dir, 'spotify_results.yml'), spotify_results.to_yaml)
