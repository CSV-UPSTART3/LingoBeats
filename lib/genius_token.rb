# frozen_string_literal: true

require 'http'
require 'yaml'

module LingoBeats

  # Token manager class (similar to SpotifyTokenManager)
  class GeniusTokenManager
    attr_reader :access_token

    def initialize(config = LingoBeats::CONFIG)
      @access_token = config['GENIUS_CLIENT_ACCESS_TOKEN']
    end
  end

  # Global module providing a simple interface
  module GeniusToken
    module_function

    def access_token
      @manager ||= GeniusTokenManager.new
      @manager.access_token
    end
  end
end
