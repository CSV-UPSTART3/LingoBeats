# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require_relative 'spotify_api'
require_relative 'genius_api'
require_relative 'gemini_api'

dir = 'spec/fixtures'
FileUtils.mkdir_p(dir)

# --- call spotify api ---
spotify_client = LingoBeats::SpotifyClient.new
spotify_artist_result = spotify_client.search_songs_by_artist('Ed Sheeran')
spotify_song_name_result = spotify_client.search_song_by_name('peach')

File.write(File.join(dir, 'spotify_artist_result.yml'), spotify_artist_result.to_yaml)
File.write(File.join(dir, 'spotify_song_name_result.yml'), spotify_song_name_result.to_yaml)

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
