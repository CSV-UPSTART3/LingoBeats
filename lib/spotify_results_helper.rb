# frozen_string_literal: true

module LingoBeats
  # Normalize the return result in search
  module SpotifyTracksResultNormalizer
    module_function

    # In specific order
    FIELD_KEYS = %i[
      artist track popularity track_id uri external_url
      artist_id artist_url album_name album_id album_url album_image
    ].freeze

    FIELD_METHODS = %i[
      artist_name track_name track_popularity track_id track_uri track_url
      artist_id artist_url album_name album_id album_url album_image_url
    ].freeze

    NORMALIZED_FIELDS = FIELD_KEYS.zip(FIELD_METHODS).to_h.freeze

    def normalize_results(search_result)
      items = Array(search_result.dig('tracks', 'items'))
      items.map { |track| normalize_track(track) }
    end

    def normalize_track(track)
      NORMALIZED_FIELDS.transform_values { |method_name| send(method_name, track) }
    end

    # --- helpers ---

    # track
    def track_name(track) = track['name']

    def track_id(track) = track['id']

    def track_uri(track) = track['uri']

    def track_url(track) = track.dig('external_urls', 'spotify')

    def track_popularity(track) = track['popularity']

    # artist
    def artist_info(track) = track['artists']&.first || {}

    def artist_name(track) = artist_info(track)['name'] || 'Unknown Artist'

    def artist_id(track) = artist_info(track)['id']

    def artist_url(track) = artist_info(track).dig('external_urls', 'spotify')

    # album
    def album_info(track) = track['album'] || {}

    def album_name(track) = album_info(track)['name']

    def album_id(track) = album_info(track)['id']

    def album_url(track) = album_info(track).dig('external_urls', 'spotify')

    def album_image_url(track) = album_info(track).dig('images', 0, 'url')

    private_class_method :normalize_track, :artist_info, :album_info
  end
end
