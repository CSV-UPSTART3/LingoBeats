# frozen_string_literal: true

require 'json'
require 'http'

module LingoBeats
  module Gemini
    # 組 URL → 發 HTTP POST → 回 Ruby Hash
    class Api
      BASE  = 'https://generativelanguage.googleapis.com/v1/models'
      MODEL = 'gemini-2.5-flash'

      def initialize(token_provider:, model: MODEL, http_client: HTTP)
        @token_provider = token_provider
        @model          = model
        @http           = http_client
      end

      # prompt: String or Array<String>
      def generate_content(prompt)
        validate_prompt!(prompt)
        resp = @http.post(request_url, json: request_body(prompt))
        JSON.parse(resp.to_s)
      end

      private

      def validate_prompt!(prompt)
        raise ArgumentError, 'prompt required' if prompt.nil? || (prompt.respond_to?(:empty?) && prompt.empty?)
      end

      def request_url
        "#{BASE}/#{@model}:generateContent?key=#{@token_provider.api_key}"
      end

      def request_body(prompt)
        { contents: [{ role: 'user', parts: build_parts(prompt) }] }
      end

      def build_parts(prompt)
        arr = prompt.is_a?(Array) ? prompt : [prompt]
        arr.map { |t| { text: t.to_s } }
      end
    end
  end
end
