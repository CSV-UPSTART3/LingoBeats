# frozen_string_literal: true

require_relative 'spotify_object/track'

module LingoBeats
  # Handles normalization of Spotify Track data
  module SpotifyTrackNormalizer
    FIELD_ORDER = %i[
      artist_name track_name track_id track_uri external_url
      artist_id artist_url album_name album_id album_url album_image
    ].freeze

    module_function

    # normalize a single Track object
    def normalize_track(track)
      FIELD_ORDER.to_h { |key| [key, track.public_send(key)] }
    end

    # normalize response in a payload
    def normalize_results(payload)
      items = Array(payload.dig('tracks', 'items'))
      items.map { |data| normalize_track(LingoBeats::Track.new(data)) }
    end
  end
end
