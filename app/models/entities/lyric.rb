# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module LingoBeats
  module Entity
    # Domain entity for song
    class Lyric < Dry::Struct
      include Dry.Types

      attribute :id,              Strict::String
      attribute :lyric,           Strict::String

      def to_attr_hash
        {
          id: id,
          lyric: lyric
        }
      end
    end
  end
end
