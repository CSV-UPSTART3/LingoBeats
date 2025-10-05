# frozen_string_literal: true

require 'http'
require 'base64'
require 'yaml'
require_relative 'http_helper'

CONFIG = YAML.safe_load_file('config/secrets.yml')

# Get and cache Spotify client_credentials token
# - Refreshes 60 seconds before expiration
module SpotifyToken
  TOKEN_URL = 'https://accounts.spotify.com/api/token'
  EXPIRY_BUFFER = 60

  module_function

  def access_token
    return @token if valid?

    data = request_token
    @token = data['access_token']
    @expires_at = new_expire_time(data)
    @token
  end

  # --- helpers ---

  def valid?
    @token && @expires_at && Time.now < (@expires_at - EXPIRY_BUFFER)
  end

  def request_token
    res = HTTP.headers(
      'Authorization' => "Basic #{client_token}",
      'Content-Type' => 'application/x-www-form-urlencoded'
    ).post(TOKEN_URL, form: { grant_type: 'client_credentials' })
    HttpHelper.parse_json!(res)
  end

  def client_token
    Base64.strict_encode64("#{CONFIG['SPOTIFY_CLIENT_ID']}:#{CONFIG['SPOTIFY_CLIENT_SECRET']}")
  end

  def new_expire_time(data)
    ttl = Integer(data['expires_in'] || 3600)
    Time.now + ttl
  end

  private_class_method :valid?, :request_token, :client_token, :new_expire_time
end
