# frozen_string_literal: true

require 'roda'
require 'yaml'

module LingoBeats
  # Configuration for the App
  class App < Roda
    CONFIG = YAML.safe_load_file('config/secrets.yml')
    SPOTIFY_CLIENT_ID = CONFIG['SPOTIFY_CLIENT_ID']
    SPOTIFY_CLIENT_SECRET = CONFIG['SPOTIFY_CLIENT_SESCRET']
  end
end