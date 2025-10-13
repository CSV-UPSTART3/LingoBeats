# frozen_string_literal: true

module LingoBeats
  # Data parsing model for Spotify Album
  class Album
    def initialize(data)
      @data = data || {}
    end

    def self.from_track(track)
      new(track['album'])
    end

    def name = @data['name']
    def id = @data['id']
    def url = @data.dig('external_urls', 'spotify')
    def image_url = @data.dig('images', 0, 'url')
  end
end
