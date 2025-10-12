# frozen_string_literal: true

module LingoBeats
  # Data parsing model for Spotify Artist
  class Artist
    def initialize(data)
      @data = data || {}
    end

    def self.from_track(track)
      artists = Array(track['artists']).first || {}
      new(artists)
    end

    def name = @data['name']
    def id = @data['id']
    def url = @data.dig('external_urls', 'spotify')
  end
end
