# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module LingoBeats
  module Entity
    # Domain entity for search history
    class SearchHistory < Dry::Struct
      include Dry.Types()

      MAX = 6

      attribute :song_names, Array.of(String)
      attribute :singers,    Array.of(String)

      def add(change = {})
        apply(change) { |list, query| ([query] + (list - [query])).take(MAX) }
      end

      def remove(change = {})
        apply(change) { |list, query| list - [query] }
      end

      def to_h
        {
          song_search_history: song_names,
          singer_search_history: singers
        }
      end

      private

      def apply(change)
        query = change[:query].to_s.strip
        return self if query.empty?

        attr = change[:category].to_s == 'singer' ? :singers : :song_names
        new(attributes.merge(attr => yield(public_send(attr), query)))
      end
    end
  end
end
