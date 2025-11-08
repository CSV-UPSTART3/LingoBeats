# frozen_string_literal: true

require 'figaro'
require 'logger'
require 'rack/session/cookie'
require 'roda'
require 'sequel'
require 'yaml'

module LingoBeats
  # Configuration for the App
  class App < Roda
    plugin :environments

    # Environment variables setup
    Figaro.application = Figaro::Application.new(
      environment: ENV.fetch('RACK_ENV', 'development'),
      path: File.expand_path('config/secrets.yml')
    )
    Figaro.load
    def self.config = Figaro.env

    raise 'Missing SESSION_SECRET!' unless config.SESSION_SECRET
    use Rack::Session::Cookie, secret: config.SESSION_SECRET

    configure :development, :test do
      require 'pry'; # for breakpoints
      ENV['DATABASE_URL'] = "sqlite://#{config.DB_FILENAME}"
    end

    # Database Setup
    @db = Sequel.connect(ENV.fetch('DATABASE_URL'))
    def self.db = @db # rubocop:disable Style/TrivialAccessors

    # Logger Setup
    @logger = Logger.new($stderr)
    class << self
      attr_reader :logger
    end
  end
end
