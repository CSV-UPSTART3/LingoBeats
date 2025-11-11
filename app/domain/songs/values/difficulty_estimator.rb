require 'open3'
require 'json'

module LingoBeats
  module Value
    class DifficultyEstimator
      def initialize(words)
        @words = words
      end

      def call
        return {} if @words.empty?

        # 將 words 轉成逗號分隔字串傳給 Python
        command = [
          "python3",
          "app/domain/songs/services/cefrpy_service.py",
          @words.join(",")
        ]

        stdout, stderr, status = Open3.capture3(*command)
        if status.success?
          JSON.parse(stdout)
        else
          warn "Python failed (#{status.exitstatus}): #{stderr}"
          {}
        end
      end
    end
  end
end