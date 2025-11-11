# frozen_string_literal: true

require 'rack/cors'

require_relative 'require_app'

require_app

use Rack::Cors do
  allow do
    origins '*'
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end

run LingoBeats::App.freeze.app
