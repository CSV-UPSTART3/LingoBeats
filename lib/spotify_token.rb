# frozen_string_literal: true

require 'http'
require 'base64'
require 'yaml'
require_relative 'http_helper'

module LingoBeats
  # __dir__ returns the directory of the current file
  ROOT = File.expand_path('../', __dir__)
  CONFIG = YAML.safe_load_file(File.join(ROOT, 'config/secrets.yml'))

  # manages Spotify token lifecycle
  class SpotifyTokenManager
    TOKEN_URL = 'https://accounts.spotify.com/api/token'
    EXPIRY_BUFFER = 60

    def initialize(config = CONFIG)
      @client_id = config['SPOTIFY_CLIENT_ID']
      @client_secret = config['SPOTIFY_CLIENT_SECRET']
      @token = nil
      @expires_at = nil
    end

    def access_token
      return @token if valid?

      data = request_token
      @token = data['access_token']
      @expires_at = new_expire_time(data)
      @token
    end

    private

    def valid?
      @token && @expires_at && Time.now < (@expires_at - EXPIRY_BUFFER)
    end

    def request_token
      # form 型態會自己設 Content-Type: application/x-www-form-urlencoded
      HttpHelper::Request.new('Authorization' => "Basic #{client_token}")
                         .post(TOKEN_URL, form: { grant_type: 'client_credentials' })
    end

    def client_token
      Base64.strict_encode64("#{@client_id}:#{@client_secret}")
    end

    def new_expire_time(data)
      ttl = Integer(data['expires_in'] || 3600)
      Time.now + ttl
    end
  end

  # global usage interface
  module SpotifyToken
    module_function

    def access_token
      @manager ||= SpotifyTokenManager.new
      @manager.access_token
    end
  end
end
