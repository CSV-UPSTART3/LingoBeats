require 'minitest/autorun'
require 'minitest/rg'
require 'yaml'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'spotify_api'

ARTIST_NAME = 'Olivia Rodrigo'
SONG_NAME = 'little more'
CONFIG = YAML.safe_load(File.read('config/secrets.yml'))
CORRECT_RESULT = YAML.safe_load(File.read('spec/fixtures/spotify_song_result.yml'), permitted_classes: [Symbol])
CORRECT_RESULTS = YAML.safe_load(File.read('spec/fixtures/spotify_song_results.yml'), permitted_classes: [Symbol])

# puts CORRECT_RESULT.size

describe 'Tests Spotify API library' do
  describe 'A Song information' do
    it 'HAPPY: should provide correct attributes of songs' do
      spotify_client = LingoBeats::SpotifyClient.new.search_song_by_name(SONG_NAME)
      _(spotify_client).must_equal CORRECT_RESULT
      _(spotify_client[0].size).must_equal CORRECT_RESULT[0].size
      _(spotify_client[0][:track]).must_equal CORRECT_RESULT[0][:track]
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
      spotify_client = LingoBeats::SpotifyClient.new.search_songs_by_artist(ARTIST_NAME, limit: 3)
      puts spotify_client.size
      puts spotify_client[0]
      _(spotify_client).must_equal CORRECT_RESULTS
      _(spotify_client.size).must_equal CORRECT_RESULTS.size
      _(spotify_client[0].size).must_equal CORRECT_RESULTS[0].size
      _(spotify_client[0][:track]).must_equal CORRECT_RESULTS[0][:track]
    end
  end
end
