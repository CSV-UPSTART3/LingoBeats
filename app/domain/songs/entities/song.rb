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
        to_h.except(:lyric, :singers)
      end

      # Remove duplicates by name + first singer id
      def ==(other)
        other.respond_to?(:comparison_key) && comparison_key == other.comparison_key
      end
      alias eql? ==

      def comparison_key
        [name, singers.first&.id]
      end

      def hash
        comparison_key.hash
      end

      # Check if the song is instrumental version
      def instrumental?
        song_name = name.to_s.downcase
        song_name.include?('instrumental')
      end
    end
  end
end
