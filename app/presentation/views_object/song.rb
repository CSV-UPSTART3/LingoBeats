# frozen_string_literal: true

require_relative 'singer'

module Views
  # View for a single song entity
  class Song
    def initialize(song)
      @song = song
    end

    def entity
      @song
    end

    def id
      @song.id
    end

    def name
      @song.name
    end

    def external_url
      @song.external_url
    end

    def singers
      @song.singers.map { |singer| Views::Singer.new(singer).to_view }
    end

    def album_name
      @song.album_name
    end

    def album_image_url
      @song.album_image_url
    end
  end
end
