# frozen_string_literal: true

module Views
  # View for a single singer entity
  class Singer
    def initialize(singer)
      @singer = singer
    end

    def entity
      @singer
    end

    def id
      @singer.id
    end

    def name
      @singer.name
    end

    def external_url
      @singer.external_url
    end

    def to_view
      {
        name: name,
        external_url: external_url
      }
    end
  end
end
