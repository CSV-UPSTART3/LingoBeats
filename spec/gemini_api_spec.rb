# frozen_string_literal: true

require_relative 'helpers/spec_helper'
require_relative 'helpers/vcr_helper'
require_relative 'helpers/yaml_helper'
require 'json'
require 'sequel'

describe 'Tests Gemini API → Material pipeline' do
  before do
    VcrHelper.setup_vcr
    VcrHelper.configure_vcr_for_gemini
  end

  after do
    VcrHelper.eject_vcr
  end

  it 'HAPPY: builds Material entity and persists to DB' do
    gemini_key = defined?(GEMINI_API_KEY) ? GEMINI_API_KEY : ENV.fetch('GEMINI_API_KEY', nil)
    skip 'GEMINI_API_KEY not set; skipping integration spec' unless gemini_key

    # --- DB 連線 ---
    db_url = ENV['DATABASE_URL'] || 'sqlite://db/development.db'
    Sequel::Model.db ||= Sequel.connect(db_url)

    # --- gateway ---
    token_provider = Module.new do
      define_singleton_method(:api_key) { gemini_key }
    end

    api = LingoBeats::Gemini::Api.new(token_provider: token_provider)

    level   = 'A2'
    song_id = 'spotify:track:test-123'
    lyrics  = 'Love me like you do...'

    prompt = <<~PROMPT
      You are an English learning assistant for level #{level}.
      Return ONLY compact JSON with keys:
      {"summary":"...","vocabulary":[{"word":"...","definition":"...","example":"..."}],"phrases":[{"phrase":"...","meaning":"...","example":"..."}]}
      No commentary. No markdown. JSON only.

      Lyrics:
      #{lyrics}
    PROMPT

    payload = api.generate_content(prompt)

    # --- Mapper 直接產生 Domain Entity（和 SongMapper 用法一致）---
    entity = LingoBeats::Gemini::MaterialMapper.build_entity(
      payload, song_id:, level:
    )

    _(entity).wont_be_nil
    _(entity).must_be_kind_of LingoBeats::Entity::Material
    _(entity.song_id).must_equal song_id
    _(entity.level).must_equal level

    parsed = JSON.parse(entity.content, symbolize_names: true)
    _(parsed).must_include :summary
    _(parsed).must_include :vocabulary
    _(parsed).must_include :phrases
    _(parsed[:vocabulary]).must_be_kind_of Array
    _(parsed[:phrases]).must_be_kind_of Array

    # --- 寫入 DB 並讀回驗證 ---
    saved   = LingoBeats::Repository::Materials.create(entity)
    fetched = LingoBeats::Repository::Materials.find_by_song_id(song_id)

    _(saved).must_be_kind_of LingoBeats::Entity::Material
    _(fetched).must_be_kind_of LingoBeats::Entity::Material
    _(JSON.parse(fetched.content)).must_include 'summary'
  end

  it 'SAD: raises when model output is empty/invalid' do
    bad_payload = { 'candidates' => [{ 'content' => { 'parts' => [] } }] }
    _(
      proc { LingoBeats::Gemini::MaterialMapper.build_entity(bad_payload, song_id: 'sid', level: 'A2') }
    ).must_raise RuntimeError
  end
end
