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

  # search songs through artist
  def search_songs_by_artist(query, **options)
    params = { q: "artist:\"#{query}\"", type: 'track', market: 'US' }.merge(options)
    fetch_data(api_path('search'), params: params)
  end

  # search a song through song_name
  def search_song_by_name(song_name, **options)
    params = { q: "track:\"#{song_name}\"", type: 'track', market: 'US' }.merge(options)
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
song_results = spotify_client.search_songs_by_artist('Olivia Rodri', limit: 5)
song_result = spotify_client.search_song_by_name('little more', limit: 1)

## HAPPY project request
spotify_song_results = SpotifyTracksResultNormalizer.normalize_results(song_results)
spotify_song_result = SpotifyTracksResultNormalizer.normalize_results(song_result)

dir = 'spec/fixtures'
FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
File.write(File.join(dir, 'spotify_song_results.yml'), spotify_song_results.to_yaml)
File.write(File.join(dir, 'spotify_song_result.yml'), spotify_song_result.to_yaml)
