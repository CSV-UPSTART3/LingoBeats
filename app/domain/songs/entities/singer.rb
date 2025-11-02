# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module LingoBeats
  module Entity
    # Domain entity for song
    class Singer < Dry::Struct
      include Dry.Types

      attribute :id,              Strict::String
      attribute :name,            Strict::String
      attribute :external_url,    Strict::String

      def to_attr_hash
        to_h
      end
    end
  end
end
