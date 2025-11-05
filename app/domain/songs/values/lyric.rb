# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'
require 'digest'

module LingoBeats
  module Value
    # Domain value object for song
    class Lyric < Dry::Struct
      include Dry.Types

      attribute :text, Strict::String.optional

      # get id by checksum of normalized text
      def checksum
        Digest::SHA256.hexdigest(normalized_text)
      end

      def normalized_text
        (text || '').strip.gsub(/\s+/, ' ')
      end
    end
  end
end
