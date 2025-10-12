# frozen_string_literal: true

require 'rake/testtask'
require 'fileutils'

CODE_DIR = 'lib'

task default: :spec

# run all test
desc 'run tests'
# 單一檔案
# task :spec do
#   sh 'ruby spec/spotify_api_spec.rb'
# end

# 多檔案
Rake::TestTask.new(:spec) do |t|
  t.libs << 'lib' << 'spec'
  t.pattern = 'spec/**/*_spec.rb'
  t.warning = false
end

# manage vcr record file
namespace :vcr do
  desc 'delete cassette fixtures (*.yml)'
  task :wipe do
    files = Dir['spec/fixtures/cassettes/*.yml']
    if files.empty?
      puts 'No cassettes found'
    else
      FileUtils.rm_f(files)
      puts "Cassettes deleted: #{files.size}"
    end
  end
end

# check code quality
namespace :quality do
  desc 'run all quality checks'
  task all: %i[rubocop reek flog]

  desc 'Run RuboCop'
  task :rubocop do
    puts '[RuboCop]'
    sh 'bundle exec rubocop' do
      puts # avoid aborting
    end
  end

  desc 'Run Reek'
  task :reek do
    puts '[Reek]'
    sh 'bundle exec reek' do
      puts # avoid aborting
    end
  end

  desc 'Run Flog'
  task :flog do
    puts '[Flog]'
    sh "bundle exec flog #{CODE_DIR}"
  end
end
