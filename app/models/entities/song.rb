# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module LingoBeats
  module Entity
    # Domain entity for song
    class Song < Dry::Struct
      include Dry.Types

      attribute :name,            Strict::String
      attribute :id,              Strict::String
      attribute :uri,             Strict::String
      attribute :external_url,    Strict::String
      attribute :artist_name,     Strict::String
      attribute :artist_id,       Strict::String
      attribute :artist_url,      Strict::String
      attribute :album_name,      Strict::String
      attribute :album_id,        Strict::String
      attribute :album_url,       Strict::String
      attribute :album_image_url, Strict::String
    end
  end
end
