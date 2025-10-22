# frozen_string_literal: false

require_relative '../entities/singer'

module LingoBeats
  module Spotify
    # Data Mapper: Spotify Track Artist -> Singer entity
    class SingerMapper
      def initialize(*); end

      def self.build_entities(data)
        Array(data).map { |singer| build_entity(singer).to_h }
      end

      def self.build_entity(data)
        DataMapper.new(data).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(data)
          @data = data
        end

        def build_entity
          LingoBeats::Entity::Singer.new(
            id:,
            name:,
            external_url:
          )
        end

        def id = @data['id']
        def name = @data['name']
        def external_url = @data.dig('external_urls', 'spotify')
      end
    end
  end
end
