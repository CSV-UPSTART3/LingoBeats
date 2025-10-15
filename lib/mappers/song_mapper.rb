# frozen_string_literal: false

require 'yaml'
require_relative '../entities/song'

module LingoBeats
  # Provides access to song data
  module Spotify
    # Data Mapper: Spotify Track -> Song entity
    class SongMapper
      def initialize(client_id, client_secret, gateway_class = Spotify::Api)
        @gateway_class = gateway_class
        @gateway = @gateway_class.new(client_id, client_secret)
      end

      def search_songs_by_singer(query)
        data = @gateway.songs_data(category: :artist, query: query, limit: 3)
        self.class.build_entities(data)
      end

      def search_songs_by_name(query)
        data = @gateway.songs_data(category: :song_name, query: query, limit: 3)
        self.class.build_entities(data)
      end

      def self.build_entities(data)
        Array(data.dig('tracks', 'items')).map { |track| build_entity(track).to_h }
      end

      def self.build_entity(data)
        DataMapper.new(data).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(data)
          @data = data
        end

        def build_entity
          Entity::Song.new(
            name:, id:, uri:, external_url:,
            artist_name:, artist_id:, artist_url:,
            album_name:, album_id:, album_url:, album_image_url:
          )
        end

        private

        def name = @data['name']
        def id = @data['id']
        def uri = @data['uri']
        def external_url = @data.dig('external_urls', 'spotify')

        def artist = @data['artists'].first
        def artist_name = artist['name']
        def artist_id = artist['id']
        def artist_url = artist.dig('external_urls', 'spotify')

        def album = @data['album']
        def album_name = album['name']
        def album_id = album['id']
        def album_url = album.dig('external_urls', 'spotify')
        def album_image_url = album.dig('images', 0, 'url')
      end
    end
  end
end
