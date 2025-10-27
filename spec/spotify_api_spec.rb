# frozen_string_literal: true

require_relative 'helpers/spec_helper'
require_relative 'helpers/vcr_helper'

describe 'Tests Spotify API library' do
  before do
    VcrHelper.configure_vcr_for_spotify
  end

  after do
    VcrHelper.eject_vcr
  end

  describe 'Songs information searched by song name' do
    it 'HAPPY: should provide correct attributes of songs' do
      # check size, attribute, and important value
      results = LingoBeats::Spotify::SongMapper.new(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET)
                                               .search_songs_by_song_name(SONG_NAME)

      _(results[0].size).must_equal CORRECT_RESULT_BY_SONG[0].size
      _(results[0].keys.sort).must_equal CORRECT_RESULT_BY_SONG[0].keys.sort
      # puts "RESULT id: #{results[0][:id].inspect}"
      # puts "RESULT name: #{results[0][:name].inspect}"
      _(results[0][:name]).must_equal CORRECT_RESULT_BY_SONG[0][:name]
    end
    it 'HAPPY: returns empty list when no songs matched' do
      songs = LingoBeats::Spotify::SongMapper
              .new(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET)
              .search_songs_by_song_name('totally-not-exist-zzz')

      _(songs).must_be_kind_of Array
      _(songs.length).must_equal 0
    end
    # it 'SAD: should raise exception when unauthorized' do
    #   _(proc do
    #   CodePraise::GithubApi.new('BAD_TOKEN').project('soumyaray', 'foobar')
    #   end).must_raise CodePraise::GithubApi::Errors::Unauthorized
    # end
  end

  describe 'Songs information searched by singer' do
    it 'HAPPY: should provide correct attributes of multiple songs' do
      # check size, attribute, and important value
      results = LingoBeats::Spotify::SongMapper.new(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET)
                                               .search_songs_by_singer(SINGER)
      _(results[0].size).must_equal CORRECT_RESULT_BY_SINGER[0].size
      _(results[0].keys.sort).must_equal CORRECT_RESULT_BY_SINGER[0].keys.sort
      _(results[0][:name]).must_equal CORRECT_RESULT_BY_SINGER[0][:name]
    end
    it 'HAPPY: returns empty list when no songs matched' do
      songs = LingoBeats::Spotify::SongMapper
              .new(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET)
              .search_songs_by_singer('totally-not-exist-zzz')

      _(songs).must_be_kind_of Array
      _(songs.length).must_equal 0
    end
  end
end
