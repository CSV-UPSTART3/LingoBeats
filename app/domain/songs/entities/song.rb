# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

require_relative 'singer'
require_relative '../values/lyric'

module LingoBeats
  module Entity
    # Domain entity for song
    class Song < Dry::Struct
      include Dry.Types

      attribute :id,              Strict::String
      attribute :name,            Strict::String
      attribute :uri,             Strict::String
      attribute :external_url,    Strict::String
      attribute :album_id,        Strict::String
      attribute :album_name,      Strict::String
      attribute :album_url,       Strict::String
      attribute :album_image_url, Strict::String
      attribute :lyric,           Value::Lyric.optional
      attribute :singers,         Strict::Array.of(Singer)

      def to_attr_hash
        to_h.except(:lyric, :singers)
      end

      # Remove duplicates by name + first singer id
      def ==(other)
        other.respond_to?(:comparison_key) && comparison_key == other.comparison_key
      end
      alias eql? ==

      def comparison_key
        [name, singers.first&.id]
      end

      def hash
        comparison_key.hash
      end

      # Remove unqualified songs (e.g., instrumental, non-English)
      def self.remove_unqualified_songs(songs)
        songs.select(&:qualified?)
      end

      def qualified?
        !instrumental? && english_name?
      end

      # Check if the song is instrumental version
      def instrumental?
        name.match?(/instrument(al)?/i)
      end

      # Check if the song name is in English
      def english_name?
        name.ascii_only?
        # 允許英文、數字、空白、常見符號、以及少數變音字母
        # name.match?(/\A[0-9A-Za-z\s'&.,!?\-éáíóúñÉÁÍÓÚ]+(?:\s*\(.*\))?\z/)
      end

      def evaluate_words
        return [] unless lyric

        lyric&.evaluate_difficulty || {} # 呼叫 Lyric 的斷詞邏輯，並且進行評級
      end

      def difficulty_distribution
        results = evaluate_words
        distribution = ::Hash.new(0)

        results.each_value do |level|
          distribution[level] += 1 if level
        end

        # 依序填滿所有級別，確保前端圖表有完整結構
        levels = %w[A1 A2 B1 B2 C1 C2]
        levels.each { |level| distribution[level] ||= 0 }

        levels.to_h { |level| [level, distribution[level]] }
      end

      def average_difficulty
        dist = difficulty_distribution
        return nil if dist.empty?

        total = dist.values.sum
        return nil if total.zero?

        avg_score = weighted_average_score(dist, total)
        level_scores.key(avg_score.round)
      end

      private

      def level_scores
        {
          'A1' => 1, 'A2' => 2,
          'B1' => 3, 'B2' => 4,
          'C1' => 5, 'C2' => 6
        }.freeze
      end

      def weighted_average_score(dist, total)
        weighted = dist.sum { |level, count| level_scores[level] * count }.to_f
        weighted / total
      end
    end
  end
end
