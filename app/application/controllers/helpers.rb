# frozen_string_literal: true

module LingoBeats
  module RouteHelpers
    # Application value for parsing the result from Service calls
    class ResultParser
      def self.parse(result)
        if result.failure?
          yield(nil, result.failure)
        else
          yield(result.value!, nil)
        end
      end
    end
  end
end
