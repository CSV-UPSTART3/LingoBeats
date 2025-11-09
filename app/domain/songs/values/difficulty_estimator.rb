# frozen_string_literal: true

require 'open3'
require 'json'

module LingoBeats
  module Value
    # Difficulty estimator using external Python script
    class DifficultyEstimator
      def initialize(words)
        @words = words
      end

      def call
        return {} if @words.empty?

        stdout, stderr, status = run_python(@words)
        return JSON.parse(stdout) if status.success?

        warn "Python failed (#{status.exitstatus}): #{stderr}"
        {}
      end

      private

      def run_python(words)
        command = ['python3', 'app/domain/songs/services/cefrpy_service.py', words.join(',')]
        Open3.capture3(*command)
      end
    end
  end
end
