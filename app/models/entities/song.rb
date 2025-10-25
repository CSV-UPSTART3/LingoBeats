# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

require_relative 'singer'
require_relative 'lyric'

module LingoBeats
  module Entity
    # Domain entity for song
    class Song < Dry::Struct
      include Dry.Types

      attribute :id,              Strict::String
      attribute :name,            Strict::String
      attribute :uri,             Strict::String
      attribute :external_url,    Strict::String
      attribute :album_id,        Strict::String
      attribute :album_name,      Strict::String
      attribute :album_url,       Strict::String
      attribute :album_image_url, Strict::String
      attribute :lyric,           Lyric.optional
      attribute :singers,         Strict::Array.of(Singer)

      def to_attr_hash
        {
          id: id,
          name: name,
          uri: uri,
          external_url: external_url,
          album_id: album_id,
          album_name: album_name,
          album_url: album_url,
          album_image_url: album_image_url
        }
      end
    end
  end
end
