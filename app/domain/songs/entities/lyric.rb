# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module LingoBeats
  module Entity
    # Domain entity for song
    class Lyric < Dry::Struct
      include Dry.Types

      attribute :song_id,         Strict::String
      attribute :lyric,           Strict::String

      def to_attr_hash
        {
          song_id: song_id,
          lyric: lyric
        }
      end
    end
  end
end
