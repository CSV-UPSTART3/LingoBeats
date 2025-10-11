# frozen_string_literal: true

require 'yaml'

module LingoBeats
  # Token manager for Gemini
  class GeminiTokenManager
    attr_reader :api_key

    def initialize(config = LingoBeats::CONFIG)
      @api_key = config['GEMINI_API_KEY']
    end
  end

  # Global module for accessing Gemini API key
  module GeminiToken
    module_function

    def api_key
      @manager ||= GeminiTokenManager.new
      @manager.api_key
    end
  end
end
