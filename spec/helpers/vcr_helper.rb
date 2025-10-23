# frozen_string_literal: true

require 'vcr'
require 'webmock'

# Setting up VCR
module VcrHelper
  CASSETTES_FOLDER = 'spec/fixtures/cassettes'
  CASSETTE_FILE = 'spotify_api' # store title for vcr

  def self.setup_vcr
    VCR.configure do |c|
      c.cassette_library_dir = CASSETTES_FOLDER
      c.hook_into :webmock
    end
  end

  def self.configure_vcr_for_spotify
    VCR.configure do |c|
      encoded_auth = Base64.strict_encode64("#{SPOTIFY_CLIENT_ID}:#{SPOTIFY_CLIENT_SECRET}")

      c.filter_sensitive_data('<SPOTIFY_CLIENT_ID>') { SPOTIFY_CLIENT_ID }
      c.filter_sensitive_data('<SPOTIFY_CLIENT_SECRET>') { SPOTIFY_CLIENT_SECRET }
      c.filter_sensitive_data('<SPOTIFY_BASIC_AUTH>') { encoded_auth }
      c.filter_sensitive_data('<SPOTIFY_BASIC_AUTH_ESC>') { CGI.escape(encoded_auth) }

      c.before_record do |interaction|
        if interaction.request.headers['Authorization']&.first&.start_with?('Bearer ')
          interaction.request.headers['Authorization'] = ['Bearer <SPOTIFY_ACCESS_TOKEN>']
        end

        begin
          body = JSON.parse(interaction.response.body)
          if body['access_token']
            body['access_token'] = '<SPOTIFY_ACCESS_TOKEN>'
            interaction.response.body = JSON.generate(body)
          end
        rescue JSON::ParserError
          # Ignore non-JSON response
        end
      end
    end

    VCR.insert_cassette(
      CASSETTE_FILE,
      record: :new_episodes,
      match_requests_on: %i[method uri headers]
    )
  end

  def self.eject_vcr
    VCR.eject_cassette
  end
end
