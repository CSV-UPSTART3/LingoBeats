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
        return false unless other.is_a?(Song)

        comparison_key == other.comparison_key
      end

      def comparison_key
        [name, singers.first&.id]
      end

      alias eql? ==

      def to_attr_hash
        to_h.except(:lyric, :singers)
      end
    end
  end
end
