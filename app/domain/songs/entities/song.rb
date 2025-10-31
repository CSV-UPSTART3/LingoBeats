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

      def ==(other)
        return false unless other.is_a?(Song) # 這個物件是不是某個類別（class）的實例

        first_singer_id = singers.first&.id
        other_first_singer_id = other.singers.first&.id
        name == other.name && first_singer_id == other_first_singer_id
      end

      alias eql? ==

      def hash
        [name, singers.first&.id].hash
      end

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
