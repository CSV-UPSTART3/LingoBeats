# frozen_string_literal: true

require 'http'
require 'json'
require_relative 'gemini_token'

module LingoBeats
  # --- Gemini API -> Build learning materials from lyrics text  ---
  class GeminiClient
    BASE = 'https://generativelanguage.googleapis.com/v1/models'
    MODEL = 'gemini-2.5-flash'

    def initialize(token_provider: GeminiToken, genius_client: LingoBeats::GeniusClient.new)
      @token_provider = token_provider
      @genius_client = genius_client
    end

    def build_learning_materials(query)
      lyrics = @genius_client.fetch_lyrics_from_query(query)
      prompt = <<~PROMPT
        You are an English learning assistant.
        Given these song lyrics, create short English-learning materials:
        - A list of 10 vocabulary (word, definition, example sentence)
        - A list of 5 common phrases (phrase, meaning)
        - A short summary of the lyrics (3-5 sentences)


        Lyrics:
        #{lyrics}
      PROMPT

      url = "#{BASE}/#{MODEL}:generateContent?key=#{@token_provider.api_key}"
      
      body = {
        contents: [
          { role: 'user', parts: [{ text: prompt }] }
        ]
      }

      res = HTTP.post(url, json: body)
      get_learning_materials(res)
    end

    def get_learning_materials(res)
      data = LingoBeats::HttpHelper.parse_json!(res)
      data.dig('candidates', 0, 'content', 'parts', 0, 'text')
    end
  end
end
