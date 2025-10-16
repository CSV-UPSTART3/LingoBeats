# frozen_string_literal: true

require 'base64'
require 'fileutils'
require 'http'
require 'yaml'
require_relative 'http_helper'

module LingoBeats
  module Spotify
    # Library for Spotify Web API
    class Api
      BASE_PATH = 'https://api.spotify.com/v1/'
      Credentials = Struct.new(:id, :secret) do
        # register for token management
        def key = "#{id}:#{secret}"
      end

      def initialize(client_id, client_secret)
        credential = Credentials.new(client_id, client_secret)
        @token_manager = SpotifyTokenManager.instance_for(credential)
      end

      # search songs with specified condition
      def songs_data(category:, query:, limit:)
        spec = SearchSpec.new(category: category, query: query, limit: limit)
        HttpHelper::Request.new('Authorization' => "Bearer #{@token_manager.access_token}").get(spotify_search_url('search'), params: spec.params)
      end

      private

      def spotify_search_url(method)
        "#{BASE_PATH}#{method}"
      end

      # ---- nested class (internal) ----
      # manages Spotify token lifecycle
      class SpotifyTokenManager
        TOKEN_URL = 'https://accounts.spotify.com/api/token'
        EXPIRY_BUFFER = 60
        Sync = Struct.new(:mutex, :cv, :refreshing)

        def self.instance_for(credential)
          @instances ||= {}
          @instances[credential.key] ||= new(credential)
        end

        def initialize(credential)
          @credential = credential
          @token = nil
          @expires_at = nil
          @sync = Sync.new(Mutex.new, ConditionVariable.new, false)
        end

        def access_token
          return @token if valid?

          fetch_fresh_token
        end

        private

        def fetch_fresh_token
          @sync.mutex.synchronize do
            return @token if valid?

            @sync.refreshing ? wait_if_refreshing : refresh_by_me
            @token
          end
        end

        def wait_if_refreshing
          @sync.cv.wait(@sync.mutex) while @sync.refreshing
        end

        def refresh_by_me
          @sync.refreshing = true
          begin
            issue_new_token
          ensure
            @sync.refreshing = false
            @sync.cv.broadcast
          end
        end

        def valid?
          @token && @expires_at && Time.now.utc < (@expires_at - EXPIRY_BUFFER)
        end

        def issue_new_token
          data = request_token
          @token = data['access_token']
          @expires_at = new_expire_time(data)
        end

        def request_token
          client_token = Base64.strict_encode64("#{@credential.id}:#{@credential.secret}")
          # form: will set Content-Type: application/x-www-form-urlencode automatically
          HttpHelper::Request.new('Authorization' => "Basic #{client_token}")
                             .post(TOKEN_URL, form: { grant_type: 'client_credentials' })
        end

        def new_expire_time(data)
          ttl = Integer(data['expires_in'] || 3600)
          Time.now + ttl
        end
      end

      # Function for search preparation and validation
      class SearchSpec
        QUERY_BY_CATEGORY = { 'singer' => 'artist', 'song_name' => 'track' }.freeze

        def initialize(category:, query:, limit:)
          @category = category.to_s.downcase
          @query = query
          @limit = limit

          check_category
          check_query
        end

        def check_category
          return true if QUERY_BY_CATEGORY.key?(@category)
          
          raise ArgumentError, "Unsupported search type: #{@category.inspect}"
        end

        def check_query
          return true unless @query.to_s.strip.empty?

          raise ArgumentError, 'Query cannot be blank'
        end

        def params
          {
            type: 'track',
            market: 'US',
            q: %(#{QUERY_BY_CATEGORY[@category]}:"#{@query}"),
            limit: @limit
          }
        end
      end

      private_constant :SpotifyTokenManager, :SearchSpec
    end
  end
end
