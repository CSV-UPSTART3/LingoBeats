# frozen_string_literal: true

require 'http'
require 'json'

module LingoBeats
  # Provides result parser
  module HttpHelper
    # Customizes for api error
    class ApiError < StandardError
      attr_reader :status, :body

      def initialize(message, status:, body:)
        super(message)
        @status = status
        @body = body
      end
    end

    module_function

    def parse_json!(res)
      body = parse_body(res)
      status = res.status
      raise ApiError.new('API Error', status: status.to_i, body: body) unless status.success?

      body
    end

    def parse_body(res)
      text = res.body.to_s
      text.empty? ? {} : JSON.parse(text)
    end
    private_class_method :parse_body
  end

  # Provides HTTP request helper
  class Request
    include HttpHelper

    def initialize(root, token)
      @root = root
      @token = token
    end

    def spotify_songs(method:, params: {})
      get(@root + method, params: params)
    end

    def get(url, params: {})
      http_response = HTTP.headers('Authorization' => "Bearer #{@token}").get(url, params: params)
      parse_json!(http_response)
    end
  end
end
