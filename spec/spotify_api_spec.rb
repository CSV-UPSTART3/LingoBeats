# frozen_string_literal: true

require 'base64'
require 'json'

# use spec_helper.rb(vcr + webmock)
require_relative 'spec_helper'

describe 'Tests Spotify API library' do
  VCR.configure do |c|
    c.cassette_library_dir = CASSETTES_FOLDER
    c.hook_into :webmock

    encoded_auth = Base64.strict_encode64("#{SPOTIFY_CLIENT_ID}:#{SPOTIFY_CLIENT_SECRET}")

    c.filter_sensitive_data('<SPOTIFY_CLIENT_ID>') { SPOTIFY_CLIENT_ID }
    c.filter_sensitive_data('<SPOTIFY_CLIENT_SECRET>') { SPOTIFY_CLIENT_SECRET }
    c.filter_sensitive_data('<SPOTIFY_BASIC_AUTH>') { encoded_auth }
    c.filter_sensitive_data('<SPOTIFY_BASIC_AUTH_ESC>') { CGI.escape(encoded_auth) }
    c.before_record do |interaction|
      if interaction.request.headers['Authorization']&.first&.start_with?('Bearer ')
        interaction.request.headers['Authorization'] = ['Bearer <SPOTIFY_ACCESS_TOKEN>']
      end

      begin
        body = JSON.parse(interaction.response.body)
        if body['access_token']
          body['access_token'] = '<SPOTIFY_ACCESS_TOKEN>'
          interaction.response.body = JSON.generate(body)
        end
      # Ignore non JSON response
      rescue JSON::ParserError
      end
    end
  end

  before do
    VCR.insert_cassette CASSETTE_FILE,
                        record: :new_episodes,
                        match_requests_on: %i[method uri headers]
  end

  after do
    VCR.eject_cassette
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
