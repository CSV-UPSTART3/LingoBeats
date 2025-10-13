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
      http_response = HTTP.headers(
        'Authorization' => "Basic #{client_token}",
        'Content-Type' => 'application/x-www-form-urlencoded'
      ).post(TOKEN_URL, form: { grant_type: 'client_credentials' })
      Response.new(http_response).parse_result
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
