# frozen_string_literal: true

require 'fileutils'
require 'http'
require 'yaml'
require 'json'
require 'nokogiri'
require_relative 'http_helper'
require_relative 'spotify_token'
require_relative 'spotify_results_helper'
require_relative 'genius_token'
require_relative 'genius_scraper'
require_relative 'gemini_token'

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

# --- Genius API -> Retrieve a song's URL and HTML ---
class GeniusClient
  BASE = 'https://api.genius.com'

  def initialize(token_provider: GeniusToken)
    @token_provider = token_provider
    # build an HTTP client with the token
    @res = HTTP.headers(
      'Authorization' => "Bearer #{@token_provider.access_token}",
      'User-Agent' => 'LingoBeats'
    )
  end

  # Pick the first result’s lyrics page URL from the search results
  def first_lyrics_url(query)
    hits = search(query).dig('response', 'hits') || []
    hit = hits.first or raise "No results for: #{query}"
    hit.dig('result', 'url') or raise 'No URL in first result'
  end

  # Fetch the lyrics page HTML and extract the lyrics text
  def fetch_lyrics(url)
    res = @res.get(url)
    status = res.status
    raise "Fetch lyrics page failed: #{status}" unless status.success?

    Nokogiri::HTML(res.to_s)
  end

  private

  # Search for a song (by song name, optional artist)
  def search(query)
    res = @res.get("#{BASE}/search", params: { q: query })
    HttpHelper.parse_json!(res)
  end
end

# --- Gemini API -> Build learning materials from lyrics text  ---
class GeminiClient
  BASE = 'https://generativelanguage.googleapis.com/v1/models'
  MODEL = 'gemini-2.5-flash'

  def initialize(token_provider: GeminiToken)
    @token_provider = token_provider
  end

  def build_learning_materials(lyrics)
    prompt = <<~PROMPT
      You are an English learning assistant.
      Given these song lyrics, create short English-learning materials:
      - A list of 10 vocabulary (word, definition, example sentence)
      - A list of 5 common phrases (phrase, meaning)
      - A short summary of the lyrics (3-5 sentences)


      Lyrics:
      #{lyrics}
    PROMPT

    url = "#{BASE}/#{MODEL}:generateContent?key=#{@token_provider.api_key}"
    
    body = {
      contents: [
        { role: 'user', parts: [{ text: prompt }] }
      ]
    }

    resp = HTTP.post(url, json: body)
    data = JSON.parse(resp.to_s)
    data.dig('candidates', 0, 'content', 'parts', 0, 'text') 
  end
end

# --- call spotify api ---
spotify_client = SpotifyClient.new
song_results = spotify_client.search_songs_by_artist('Olivia Rodri', limit: 5)
song_result = spotify_client.search_song_by_name('little more', limit: 1)

# --- call genius api ---
client = GeniusClient.new
song_query = 'Shape of you'
url = client.first_lyrics_url(song_query)
doc = client.fetch_lyrics(url)

## HAPPY project request
spotify_song_results = SpotifyTracksResultNormalizer.normalize_results(song_results)
spotify_song_result = SpotifyTracksResultNormalizer.normalize_results(song_result)

dir = 'spec/fixtures'
FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
File.write(File.join(dir, 'spotify_song_results.yml'), spotify_song_results.to_yaml)
File.write(File.join(dir, 'spotify_song_result.yml'), spotify_song_result.to_yaml)
File.write(File.join(dir, 'url.txt'), url)
File.write(File.join(dir, 'url.html'), doc.to_html)

# Clean and extract lyrics text
lyrics = extract_lyrics(doc)
File.write(File.join(dir, 'lyrics_output.txt'), lyrics)
puts "歌詞已輸出到 spec/lyrics_output.txt"

# --- call gemini api ---
gemini_client = GeminiClient.new
lyrics = File.read(File.join(dir, 'lyrics_output.txt'))

learning_materials = gemini_client.build_learning_materials(lyrics)
File.write(File.join(dir, 'learning_materials.txt'), learning_materials)
puts "學習材料已輸出到 spec/learning_materials.txt"