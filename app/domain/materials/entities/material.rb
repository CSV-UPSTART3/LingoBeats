# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module LingoBeats
  module Entity
    # Domain entity for song
    class Material < Dry::Struct
      include Dry.Types

      attribute :song_id,      Strict::String
      attribute :level,        Strict::String
      attribute :content,      Strict::String

      def to_attr_hash
        to_h
      end
    end
  end
end
