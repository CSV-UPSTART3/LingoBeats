# frozen_string_literal: true

require 'http'
require 'json'
require 'rack/utils'

module LingoBeats
  module HttpHelper
    # Provides HTTP Request helper
    class Request
      def initialize(headers)
        @headers = headers
      end

      def get(url, params: {})
        http_response = HTTP.headers(@headers).get(url, params: params)
        Response.new(http_response).parse_result
      end

      def post(url, form: {})
        http_response = HTTP.headers(@headers).post(url, form: form)
        Response.new(http_response).parse_result
      end
    end

    # Provides HTTP Response helper with success/error
    class Response
      # generalize api exception
      class ApiError < StandardError
        attr_reader :status, :body

        HTTP_STATUS = Rack::Utils::HTTP_STATUS_CODES.freeze

        def initialize(status_code:, body: nil)
          @status_code = status_code
          @body = body
          @message = HTTP_STATUS.fetch(@status_code, 'Unknown Error')
          super(@message)
        end
      end

      def initialize(raw)
        @raw = raw
      end

      def parse_result
        status = @raw.status
        body = parsed_body
        return body if status.success?

        raise ApiError.new(status_code: status.to_i, body: body)
      end

      private

      def parsed_body
        text = @raw.body.to_s
        text.empty? ? {} : JSON.parse(text)
      end
    end
  end
end
