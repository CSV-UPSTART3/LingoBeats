# frozen_string_literal: true

require 'http'

module LingoBeats
  module Genius
    class Api
      BASE = 'https://api.genius.com'

      def initialize(token_provider:)
        @http = HTTP.headers(
          'Authorization' => "Bearer #{token_provider.access_token}",
          'User-Agent' => 'LingoBeats'
        )
      end

      # 只是 call Genius /search
      # 回傳整個 parsed JSON (Hash)
      def search(query)
        res = @http.get(
          "#{BASE}/search",
          params: { q: query }
        )
        JSON.parse(res.to_s)
      end

      # 從 Genius 給的歌曲網址把 HTML 抓回來（不是 API，是真人看的那頁）
      # 回傳 Nokogiri::HTML::Document 或 nil
      def fetch_lyrics_html(url)
        page = @http.get(url)
        return nil unless page.status.success?
        Nokogiri::HTML(page.to_s)
      end
    end
  end
end
