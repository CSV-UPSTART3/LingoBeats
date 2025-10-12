# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/rg'
require 'yaml'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'spotify_api'

# use spec_helper.rb(vcr + webmock)
require_relative 'spec_helper'

ARTIST_NAME = 'Ed Sheeran'
SONG_NAME = 'Peach'
CONFIG = YAML.safe_load_file('config/secrets.yml')
CORRECT_RESULT_BY_SONG = YAML.safe_load_file('spec/fixtures/spotify_song_name_result.yml', permitted_classes: [Symbol])
CORRECT_RESULT_BY_ARTIST = YAML.safe_load_file('spec/fixtures/spotify_artist_result.yml', permitted_classes: [Symbol])
CASSETTE_FILE = 'spotify_api' # store title for vcr

# puts CORRECT_RESULT.size

describe 'Tests Spotify API library' do
  before do
    VCR.insert_cassette CASSETTE_FILE,
                        record: :new_episodes,
                        match_requests_on: %i[method uri headers]
  end

  after do
    VCR.eject_cassette
  end
  describe 'A Song information' do
    it 'HAPPY: should provide correct attributes of songs' do
      # check size, attribute, and important value
      spotify_client = LingoBeats::SpotifyClient.new.search_song_by_name(SONG_NAME)

      # _(spotify_client).must_equal CORRECT_RESULT_BY_SONG
      _(spotify_client[0].size).must_equal CORRECT_RESULT_BY_SONG[0].size
      # _(spotify_client[0][:track]).must_equal CORRECT_RESULT_BY_SONG[0][:track]
      _(spotify_client[0].keys.sort).must_equal CORRECT_RESULT_BY_SONG[0].keys.sort
      _(spotify_client[0][:track]).must_equal CORRECT_RESULT_BY_SONG[0][:track]
    end
    # it 'SAD: should raise exception on incorrect song_name' do
    #   puts LingoBeats::SpotifyClient.new.search_song_by_name("?!@#$%^&*()")
    #   _(proc do
    #   LingoBeats::SpotifyClient.new.search_song_by_name(SONG_NAME, limit: 1)
    #   end).must_raise CodePraise::GithubApi::Errors::NotFound
    # end
    # it 'SAD: should raise exception when unauthorized' do
    #   _(proc do
    #   CodePraise::GithubApi.new('BAD_TOKEN').project('soumyaray', 'foobar')
    #   end).must_raise CodePraise::GithubApi::Errors::Unauthorized
    # end
  end
  describe 'Multiple Songs information' do
    it 'HAPPY: should provide correct attributes of multiple songs' do
      # check size, attribute, and important value
      spotify_client = LingoBeats::SpotifyClient.new.search_songs_by_artist(ARTIST_NAME)
      # puts spotify_client.size
      # puts spotify_client[0]
      # _(spotify_client).must_equal CORRECT_RESULT_BY_ARTIST
      # _(spotify_client.size).must_equal CORRECT_RESULT_BY_ARTIST.size
      _(spotify_client[0].size).must_equal CORRECT_RESULT_BY_ARTIST[0].size
      _(spotify_client[0].keys.sort).must_equal CORRECT_RESULT_BY_ARTIST[0].keys.sort
      _(spotify_client[0][:track]).must_equal CORRECT_RESULT_BY_ARTIST[0][:track]
    end
  end
end
