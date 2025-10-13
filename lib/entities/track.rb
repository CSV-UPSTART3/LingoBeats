# frozen_string_literal: true

require_relative 'album'
require_relative 'artist'

module LingoBeats
  # Data parsing model for Spotify Track
  class Track
    def initialize(data)
      @data = data || {}
      @artist = LingoBeats::Artist.from_track(@data)
      @album  = LingoBeats::Album.from_track(@data)
    end

    def track_name = @data['name']
    def track_id = @data['id']
    def track_uri = @data['uri']
    def external_url = @data.dig('external_urls', 'spotify')

    # side information: artist
    def artist_name = @artist.name
    def artist_id = @artist.id
    def artist_url = @artist.url

    # side information: album
    def album_name = @album.name
    def album_id = @album.id
    def album_url = @album.url
    def album_image = @album.image_url
  end
end
