# frozen_string_literal: true

module LingoBeats
  module Value
    # Text cleaner for song lyrics
    class Cleaner
      def initialize(raw_text)
        @raw_text = raw_text
      end

      def call
        return '' if @raw_text.nil? || @raw_text.strip.empty?

        text = @raw_text
        text = text.gsub(/[\[({].*?[\])}]/, '') # 移除中括號、圓括號、花括號內容
        text = text.gsub(/[^a-zA-Z\s'-]/, ' ') # 移除非英文與符號（保留空白、撇號）
        text.strip.gsub(/\s+/, ' ') # 清除多餘空白
      end
    end
  end
end
