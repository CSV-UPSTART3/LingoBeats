# frozen_string_literal: true

require 'http'

module LingoBeats
  module Genius
    # Handles communication with the Genius API.
    class Api
      BASE = 'https://api.genius.com'

      def initialize(token_provider:)
        @http = HTTP.headers(
          'Authorization' => "Bearer #{token_provider.access_token}",
          'User-Agent' => 'LingoBeats'
        )
      end

      # 從 Genius 給的歌曲網址把 HTML 抓回來
      # 回傳 Nokogiri::HTML::Document 或 nil
      def fetch_lyrics_html(url)
        response = @http.get(url)
        return unless response.status.success?

        self.class.parse_html(response)
      end

      def self.parse_html(response)
        Nokogiri::HTML(response.to_s)
      end

      # call Genius /search
      # 回傳整個 parsed JSON (Hash)
      def search(query)
        res = @http.get("#{BASE}/search", params: { q: query })
        raise_api_error(res) unless res.status == 200

        json = JSON.parse(res.to_s)
        raise_api_error(res, 'Unauthorized Genius token') if json['error']&.match?(/invalid_token|unauthorized/i)
        json
      end

      private

      def raise_api_error(res, _msg = nil)
        raise HttpHelper::Response::ApiError.new(
          status_code: res.status
        )
      end
    end
  end
end
