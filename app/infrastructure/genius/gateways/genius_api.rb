# frozen_string_literal: true

require 'http'
require 'nokogiri'
require 'json'
require_relative '../../spotify/gateways/http_helper'  # 如果路徑不對，調一下
# 這個 TokenProvider 先用你們的 GeniusTokenManager 也可以，下面我說怎麼接

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

      def self.access_token
        App.config.GENIUS_CLIENT_ACCESS_TOKEN
      end

      # 我給你這個方法就好：輸入歌名/歌手，輸出「純文字歌詞」或 nil
      def lyrics_for(song_name:, artist_name:)
        query = build_query(song_name, artist_name)

        url = first_lyrics_url(query)
        return nil unless url

        html_doc = fetch_lyrics_html(url)
        return nil unless html_doc

        extract_lyrics_text(html_doc)
      rescue StandardError => e
        warn "[Genius::Api] lyrics_for failed: #{e.message}"
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

      # 1) 打 /search 去找歌曲，拿第一筆結果的網址
      def first_lyrics_url(query)
        json = search(query)
        hits = json.dig('response', 'hits') || []
        first_hit = hits.first
        return nil unless first_hit
        first_hit.dig('result', 'url')
      end

      def search(query)
        res = @http.get("#{BASE}/search", params: { q: query })
        JSON.parse(res.to_s)
      end

      # 2) 拿那個網址的頁面 HTML
      def fetch_lyrics_html(url)
        page = @http.get(url)
        return nil unless page.status.success?
        Nokogiri::HTML(page.to_s)
      end

      # 3) 從 HTML 抽出歌詞文字
      def extract_lyrics_text(html_doc)
        return nil unless html_doc

        # html_doc 是 Nokogiri::HTML::Document
        # 1. 抓到所有真正歌詞段落的 div
        blocks = html_doc.css('div[class^="Lyrics__Container"]')
        return nil if blocks.empty?

        # 2. 把 <br> 先變成換行，保留段落感
        #    (這招比 .text 直接抽乾淨，因為 .text 會吃掉 <br>)
        raw_html = blocks.map { |div| div.inner_html.gsub('<br>', "\n") }.join("\n")

        # 3. 把上面那串再丟回 Nokogiri 走一次，拿出純文字
        text_only = Nokogiri::HTML(raw_html).text

        # 4. 找歌詞開始點：第一個 [Intro]/[Verse 1]/[Chorus] 這種標籤
        #    這一步是為了切掉前面一大段「217 Contributors」「Translations」之類雜訊
        lyrics_start_idx = text_only.index(/\[[A-Za-z0-9\s#]+\]/)
        core_lyrics = lyrics_start_idx ? text_only[lyrics_start_idx..] : text_only

        # 5. 美化一下區塊：
        #    - 每個 [Section] 前面空兩行
        #    - 確保 section header 自己是獨立一行
        formatted = core_lyrics
                    .gsub(/\s*\[([^\]]+)\]\s*/, "\n\n[\\1]\n") # 每段 section header 前面留空行
                    .gsub(/([a-z\)])(\[)/, "\\1\n\\2")         # 如果 header 黏在行尾，硬切行
                    .strip

        formatted
      end


      def clean_node_text(node)
        node.xpath('.//br').each { |br| br.replace("\n") }
        node.text.gsub(/\s+\n/, "\n").strip
      end
    end
  end
end
