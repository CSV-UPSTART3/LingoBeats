# frozen_string_literal: false

require_relative 'helpers/spec_helper'
require_relative 'helpers/vcr_helper'
require_relative 'helpers/database_helper'

describe 'Integration Tests of Spotify API and Database' do
  VcrHelper.setup_vcr

  before do
    VcrHelper.configure_vcr_for_spotify
  end

  after do
    VcrHelper.eject_vcr
  end

  # describe 'Retrieve and store project' do
  # ...
  # end
end