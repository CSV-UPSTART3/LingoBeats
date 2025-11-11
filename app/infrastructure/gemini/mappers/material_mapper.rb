# frozen_string_literal: true

require 'json'
require 'http'
require_relative '../../../domain/materials/entities/material'

module LingoBeats
  module Gemini
    # 把 Gemini 回傳的 JSON 解析成結構化的 LearningMaterial
    class MaterialMapper
      def self.to_material(payload)
        text = extract_text(payload)
        return nil if text.to_s.strip.empty?

        # 模型回來的是純文字或 JSON，統一成 hash
        begin
          data = JSON.parse(text)
        rescue JSON::ParserError
          # 如果模型沒照 JSON 格式回，先包成一個原始文字欄位
          data = { 'raw_text' => text }
        end

        symbolize_keys(data)
      end

      # 抽取純文字內容
      def self.extract_text(payload)
        candidate = payload.dig('candidates', 0)
        parts = candidate&.dig('content', 'parts')
        return nil unless parts.is_a?(Array) && !parts.empty?

        parts.map { |part| part['text'] }.compact.join("\n")
      end
      private_class_method :extract_text

      def self.symbolize_hash(obj)
        obj.each_with_object({}) { |(key, value), hash| hash[key.to_sym] = symbolize_keys(value) }
      end
      private_class_method :symbolize_hash

      def self.symbolize_keys(obj)
        case obj
        when Hash then symbolize_hash(obj)
        when Array then obj.map { |value| symbolize_keys(value) }
        else obj
        end
      end
      private_class_method :symbolize_keys

      # --- class methods ---

      def self.build_entities(payloads, song_id:, level:)
        Array(payloads).map { |payload| build_entity(payload, song_id:, level:) }
      end

      def self.build_entity(payload, song_id:, level:)
        DataMapper.new(payload, song_id:, level:).build_entity
      end

      # --- inner data mapper ---
      # 負責把 Gemini 回傳資料轉成 Material entity
      class DataMapper
        def initialize(payload, song_id:, level:)
          @payload = payload
          @song_id = song_id
          @level   = level
        end

        def build_entity
          parsed = parse_content(@payload)
          LingoBeats::Entity::Material.new(
            song_id: @song_id,
            level: @level,
            content: JSON.generate(parsed)
          )
        end

        private

        def parse_content(payload)
          text = extract_text(payload)
          raise 'Empty model output' if text.to_s.strip.empty?

          JSON.parse(text, symbolize_names: true)
        rescue JSON::ParserError
          { raw_text: text }
        end

        # Extract text of data
        module ExtractData
          module_function

          def extract_text(payload)
            parts = payload.dig('candidates', 0, 'content', 'parts')
            return nil unless parts.is_a?(Array) && !parts.empty?

            parts.map { |part| part['text'] }.compact.join("\n")
          end
        end
      end
    end
  end
end
