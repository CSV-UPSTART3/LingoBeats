# frozen_string_literal: true

require 'nokogiri'

module LingoBeats
  module Genius
    class LyricMapper
      def initialize(access_token, gateway_class = LingoBeats::Genius::Api)
        @gateway_class = gateway_class
        @gateway = @gateway_class.new(
          token_provider: StaticTokenProvider.new(access_token)
        )
      end

      # 小幫手類別：符合 Genius::Api 期待的介面
      class StaticTokenProvider
        def initialize(token)
          @token = token
        end

        def access_token
          @token
        end
      end

      # 對外公開的方法：
      # 給歌名/歌手名字，回傳乾淨歌詞字串，或 nil
      def lyrics_for(song_name:, artist_name:)
        query = build_query(song_name, artist_name)

        lyrics_page_url = first_lyrics_url(query)
        return nil unless lyrics_page_url

        html_doc = @gateway.fetch_lyrics_html(lyrics_page_url)
        return nil unless html_doc

        extract_lyrics_text(html_doc)
      rescue StandardError => e
        warn "[Genius::LyricMapper] lyrics_for failed: #{e.message}"
        nil
      end

      private

      def build_query(song_name, artist_name)
        if artist_name && !artist_name.strip.empty?
          "#{song_name} #{artist_name}"
        else
          song_name.to_s
        end
      end

      # 從 Genius /search JSON 拿到第一筆歌曲的網頁 url
      def first_lyrics_url(query)
        json = @gateway.search(query)
        hits = json.dig('response', 'hits') || []
        first_hit = hits.first
        return nil unless first_hit
        first_hit.dig('result', 'url')
      end

      # 把 HTML 轉成「整齊歌詞字串」
      def extract_lyrics_text(html_doc)
        return nil unless html_doc

        # 1. 找可能是歌詞的區塊
        blocks = html_doc.css('div[class^="Lyrics__Container"]')
        return nil if blocks.empty?

        # 2. 保留 <br> 換行
        raw_html = blocks
          .map { |div| div.inner_html.gsub('<br>', "\n") }
          .join("\n")

        # 3. 再跑一次 Nokogiri，把 tag 拿掉
        text_only = Nokogiri::HTML(raw_html).text

        # 4. 切掉貢獻者/廣告雜訊，只留從 [Verse]/[Chorus] 那種段落開始
        lyrics_start_idx = text_only.index(/\[[A-Za-z0-9\s#]+\]/)
        core_lyrics = lyrics_start_idx ? text_only[lyrics_start_idx..] : text_only

        # 5. 美化段落
        formatted = core_lyrics
          .gsub(/\s*\[([^\]]+)\]\s*/, "\n\n[\\1]\n") # section header 獨立一行，前面留空行
          .gsub(/([a-z\)])(\[)/, "\\1\n\\2")         # 如果 header 黏在歌詞後面就斷行
          .strip

        formatted
      end
    end
  end
end
