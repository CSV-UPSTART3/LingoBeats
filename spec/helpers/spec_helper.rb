# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'simplecov'
# Test coverage
SimpleCov.start do
  add_filter '/lib/gateways/http_helper.rb'
end

require 'yaml'

# VCR and WebMock setup for testing external API calls
require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/rg'
require 'vcr'
require 'webmock'

require_relative '../../require_app'
require_app

SINGER = 'Ed Sheeran'
SONG_NAME = 'golden'
CONFIG = YAML.safe_load_file('config/secrets.yml')
SPOTIFY_CLIENT_ID = CONFIG['SPOTIFY_CLIENT_ID']
SPOTIFY_CLIENT_SECRET = CONFIG['SPOTIFY_CLIENT_SECRET']
CORRECT_RESULT_BY_SINGER = YAML.safe_load_file('spec/fixtures/spotify_result_by_singer.yml',
                                               permitted_classes: [Symbol])
CORRECT_RESULT_BY_SONG = YAML.safe_load_file('spec/fixtures/spotify_result_by_song_name.yml',
                                             permitted_classes: [Symbol])
