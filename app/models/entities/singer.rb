# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module LingoBeats
  module Entity
    # Domain entity for song
    class Singer < Dry::Struct
      include Dry.Types

      attribute :name,            Strict::String
      attribute :id,              Strict::String
      attribute :external_url,    Strict::String
    end
  end
end
