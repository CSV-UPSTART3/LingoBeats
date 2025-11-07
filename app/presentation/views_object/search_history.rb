# frozen_string_literal: true

module Views
  # View for a single search history entity
  class SearchHistory
    attr_reader :song_search_history, :singer_search_history

    def initialize(song_search_history: [], singer_search_history: [])
      @song_search_history = song_search_history
      @singer_search_history = singer_search_history
    end

    def for(category)
      category.to_s == 'singer' ? @singer_search_history : @song_search_history
    end
  end
end
