# frozen_string_literal: true

require 'http'
require 'json'
require 'rack/utils'

module LingoBeats
  module HttpHelper
    # Provides HTTP Request helper
    class Request
      def initialize(root, token)
        @root = root
        @token = token
      end

      def get(url, params: {})
        http_response = HTTP.headers('Authorization' => "Bearer #{@token}")
                            .get(url, params: params)
        Response.new(http_response).parse_result
      end
    end

    # Provides HTTP Response helper with success/error
    class Response
      # generalize api exception
      class ApiError < StandardError
        attr_reader :status, :body

        def initialize(message, status:, body: nil)
          super(message)
          @status = status
          @body = body
        end
      end

      HTTP_STATUS = Rack::Utils::HTTP_STATUS_CODES.freeze

      def initialize(raw)
        @raw = raw
      end

      def parse_params
        status_obj = @raw.status
        code = status_obj.to_i
        text = @raw.body.to_s
        body = text.empty? ? {} : JSON.parse(text)

        [status_obj, code, body]
      end

      def parse_result
        status_obj, code, body = parse_params
        return body if status_obj.success?

        msg = HTTP_STATUS[code] || 'Unknown Error'
        raise ApiError.new(msg, status: code, body: body)
      end
    end
  end
end
