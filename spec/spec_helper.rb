# frozen_string_literal: true

require 'simplecov'
# Test coverage
SimpleCov.start

# VCR and WebMock setup for testing external API calls
require 'vcr'
require 'webmock/minitest'

CASSETTES_FOLDER = 'spec/fixtures/cassettes'

VCR.configure do |c|
  c.cassette_library_dir = CASSETTES_FOLDER
  c.hook_into :webmock
  c.default_cassette_options = { record: :once }
  WebMock.disable_net_connect!(allow_localhost: true)
end
