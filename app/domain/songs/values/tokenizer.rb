module LingoBeats
  module Value
    class Tokenizer
      def initialize(cleaned_text)
        @cleaned_text = cleaned_text
      end
      
      def call
        return [] if @cleaned_text.nil? || @cleaned_text.strip.empty?
        
        cleaned_text = @cleaned_text

        # 英文斷詞
        words = cleaned_text.downcase.scan(/[a-z']+/)

        # 一般英文停用詞（可外部讀入 stopwords.txt）
        common_stopwords = %w[a an the in on at for to of is am are was were do did have has had and or but]

        # 歌詞專用停用詞
        lyric_stopwords = %w[
          verse chorus bridge outro pre-chorus post-chorus
          oh ah hah yeah woah ooh la na uh yo hey ha haaa
        ]
        stopwords = (common_stopwords + lyric_stopwords).map(&:downcase).to_set
        filtered = words.reject { |word| stopwords.include?(word) }
        filtered.uniq
      end
    end
  end
end