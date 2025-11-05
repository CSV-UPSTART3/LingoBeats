# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

require_relative 'singer'
require_relative '../values/lyric'

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
      attribute :lyric,           Value::Lyric.optional
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

      # Remove unqualified songs (e.g., instrumental, non-English)
      def self.remove_unqualified_songs(songs)
        songs.select(&:qualified?)
      end

      def qualified?
        !instrumental? && english_name?
      end

      # Check if the song is instrumental version
      def instrumental?
        name.match?(/instrument(al)?/i)
      end

      # Check if the song name is in English
      def english_name?
        name.ascii_only?
      end
    end
  end
end
