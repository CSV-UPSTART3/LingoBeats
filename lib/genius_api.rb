# frozen_string_literal: true

require 'http'
require_relative 'genius_token'
require_relative 'genius_scraper'
require_relative 'http_helper'

module LingoBeats
  # --- Genius API -> Retrieve a song's URL and HTML ---
  class GeniusClient
    BASE = 'https://api.genius.com'

    def initialize(token_provider: GeniusToken, scraper: LingoBeats::Scraper.new)
      @token_provider = token_provider
      @scraper = scraper
      # build an HTTP client with the token
      @res = HTTP.headers(
        'Authorization' => "Bearer #{@token_provider.access_token}",
        'User-Agent' => 'LingoBeats'
      )
    end

    def fetch_lyrics_from_query(query)
      url = first_lyric_url(query)
      raise "No lyrics found for #{query}" unless url
      fetch_lyrics(url)
    end

    # Fetch the lyrics page HTML and extract the lyrics text
    def fetch_lyrics(url)
      res = @res.get(url)
      status = res.status
      raise "Fetch lyrics page failed: #{status}" unless status.success?

      @scraper.extract_lyrics(res)
    end

    private

    def first_lyric_url(query)
      hit = search_lyric_urls(query).first or raise "No results for: #{query}"
      hit.dig('result', 'url') or raise 'No URL in first result'
    end

    def search_lyric_urls(query)
      search(query).dig('response', 'hits') || []
    end

    # Search for a song (by song name, optional artist)
    def search(query)
      res = @res.get("#{BASE}/search", params: { q: query })
      LingoBeats::HttpHelper.parse_json!(res)
    end
  end
end