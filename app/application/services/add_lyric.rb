# frozen_string_literal: true

require 'dry/transaction'

module LingoBeats
  module Service
    # Transaction to store lyric when user selects a song
    class AddLyric
      include Dry::Transaction

      step :parse_url
      step :find_lyric
      step :check_song_exists
      step :store_lyric

      def initialize(repo: Repository::For.klass(Value::Lyric),
                     mapper: Genius::LyricMapper.new(App.config.GENIUS_CLIENT_ACCESS_TOKEN))
        super()
        @repo = repo
        @lyric_provider = LyricProvider.new(mapper)
      end

      private

      # step 1. parse id/name/singer from request URL
      def parse_url(input)
        return Failure("URL #{input.errors.messages.first}") unless input.success?

        params = ParamExtractor.call(input)
        Success(params)
      end

      # step 2. find if lyric already exists in db, else fetch from Genius API
      def find_lyric(input)
        if (lyric = lyric_in_database(input))
          input[:local_lyric] = lyric
        else
          input[:remote_lyric] = @lyric_provider.fetch(input)
        end
        Success(input)
      rescue StandardError => error
        Failure(error.to_s)
      end

      # step 3. check if song exists
      def check_song_exists(input)
        add_song_result = Service::AddSong.new.call(input[:song_id])
        return Failure(add_song_result.failure) if add_song_result.failure?

        Success(input)
      rescue StandardError => error
        Failure(error.to_s)
      end

      # step 4. store lyric if not exists, and return lyric value object
      def store_lyric(input)
        lyric =
          if (new_lyric = input[:remote_lyric])
            @repo.attach_to_song(input[:song_id], new_lyric)
          else
            input[:local_lyric]
          end
        Success(lyric)
      rescue StandardError => error
        App.logger.error error.backtrace.join("\n")
        Failure('Failed to store lyric to database')
      end

      # support methods
      def lyric_in_database(input)
        @repo.for_song(input[:song_id])
      end

      # parameter extractor
      class ParamExtractor
        def self.call(request)
          params = request.to_h
          { song_id: params[:id], song_name: params[:name], singer_name: params[:singer] }
        end
      end

      # fetch lyric from Genius API
      class LyricProvider
        # custom error for fetch failure
        class FetchError < StandardError; end

        def initialize(mapper)
          @mapper = mapper
        end

        def fetch(input)
          lyric = @mapper.lyrics_for(song_name: input[:song_name], singer_name: input[:singer_name])
          validate_lyric(lyric)
        rescue StandardError
          raise FetchError, 'Failed to load lyrics.'
        end

        private

        def validate_lyric(lyric)
          raise 'Oops! Something went wrong with the lyrics.' if lyric.text.strip.empty?
          raise 'This song is not recommended for English learners.' unless lyric.english?

          lyric
        end
      end
    end
  end
end
