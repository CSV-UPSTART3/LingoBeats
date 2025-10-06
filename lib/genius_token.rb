# frozen_string_literal: true

require 'http'
require 'yaml'

# CONFIG = YAML.safe_load_file('config/secrets.yml')

# Token manager class (similar to SpotifyTokenManager)
class GeniusTokenManager
  attr_reader :access_token

  def initialize(config = CONFIG)
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
