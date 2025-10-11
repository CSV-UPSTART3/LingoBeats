# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require_relative 'spotify_api'
require_relative 'genius_api'
require_relative 'gemini_api'

dir = 'spec/fixtures'
FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

# --- call spotify api ---
spotify_client = LingoBeats::SpotifyClient.new
spotify_song_results = spotify_client.search_songs_by_artist('Olivia Rodrigo', limit: 3)
spotify_song_result = spotify_client.search_song_by_name('little more')
File.write(File.join(dir, 'spotify_song_results.yml'), spotify_song_results.to_yaml)
File.write(File.join(dir, 'spotify_song_result.yml'), spotify_song_result.to_yaml)

# # --- call genius api ---
# genius_client = LingoBeats::GeniusClient.new

# # Clean and extract lyrics text
# query = 'Shape of you'
# lyrics = genius_client.fetch_lyrics_from_query(query)
# File.write(File.join(dir, 'lyrics_output.txt'), lyrics)
# puts "歌詞已輸出到 spec/lyrics_output.txt"

# # --- call gemini api ---
# gemini_client = LingoBeats::GeminiClient.new
# learning_materials = gemini_client.build_learning_materials(query)
# File.write(File.join(dir, 'learning_materials.txt'), learning_materials)
# puts "學習材料已輸出到 spec/learning_materials.txt"