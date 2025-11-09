# frozen_string_literal: true

# 執行方式：
#   ruby app/infrastructure/gemini/test.rb
#
# 需求：
#   - 已安裝 gem 'http'
#   - 你的金鑰可由 LingoBeats::GeminiToken 取得（或自行改為 ENV 讀取）

require 'json'
require 'yaml'
require 'http'

# --- 1) 先把 DB 連線準備好（在載入任何 ORM/Repo 前）---
require 'sequel'

# 如果你想沿用 App 的環境設定（方法一）
require_relative '../../../config/environment' # 這支會做 Sequel.connect(...) 並放在 LingoBeats::App.db
app_db = defined?(LingoBeats::App) && LingoBeats::App.respond_to?(:db) ? LingoBeats::App.db : nil

# 安全保險：若 App.db 沒設好，就退回 DATABASE_URL 或開發用 sqlite
Sequel::Model.db = app_db || Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://db/development.db')

# （可選）除錯看看
puts "[DEBUG] DB set? #{!Sequel::Model.db.nil?}"
puts "[DEBUG] tables: #{Sequel::Model.db.tables.inspect}"

# --- 2) 再載 ORM / Repo / 其他 ---
require_relative '../database/orm/material_orm'
require_relative '../database/repositories/materials'

# 根據你的專案路徑調整 require_relative
require_relative 'gateways/gemini_api'
require_relative 'mappers/material_mapper'

# 如果你之前是用 secrets.yml 載入金鑰，這裡沿用；否則改讀 ENV['GEMINI_API_KEY']
# --- 簡易 token provider（ENV 優先，否則讀 config/secrets.yml）---
module LingoBeats
  module GeminiToken
    module_function

    def api_key
      return ENV['GEMINI_API_KEY'] if ENV['GEMINI_API_KEY'] && !ENV['GEMINI_API_KEY'].empty?

      config_path = File.expand_path('../../../config/secrets.yml', __dir__)
      if File.exist?(config_path)
        config = YAML.safe_load_file(config_path)
        return config['GEMINI_API_KEY']
      end
      nil
    end
  end
end

def assert!(cond, msg)
  abort("[TEST] ❌ #{msg}") unless cond
end

puts '[TEST] start…'

# 1) 取得金鑰
api_key = LingoBeats::GeminiToken.api_key
assert!(api_key && !api_key.strip.empty?, '找不到 GEMINI_API_KEY')

# 2) 準備 gateway
api = LingoBeats::Gemini::Api.new(token_provider: LingoBeats::GeminiToken)

# 3) 準備測試輸入
song_id = 'spotify:track:test-123'
level   = 'A2'
lyrics  = <<~LYRICS
  Love me like you do, love me like you do…
  Touch me like you do, touch me like you do…
LYRICS

prompt = <<~PROMPT
  You are an English learning assistant for level #{level}.
  Return ONLY compact JSON with keys:
  {
    "summary": "string (<= 5 sentences)",
    "vocabulary": [
      {"word":"...", "definition":"...", "example":"..."},
      {"word":"...", "definition":"...", "example":"..."},
      {"word":"...", "definition":"...", "example":"..."},
      {"word":"...", "definition":"...", "example":"..."},
      {"word":"...", "definition":"...", "example":"..."}
    ],
    "phrases": [
      {"phrase":"...", "meaning":"...", "example":"..."},
      {"phrase":"...", "meaning":"...", "example":"..."},
      {"phrase":"...", "meaning":"...", "example":"..."}
    ]
  }
  No commentary. No markdown. JSON only.

  Lyrics:
  #{lyrics}
PROMPT

begin
  # 4) 呼叫 Gateway
  payload = api.generate_content(prompt)
  puts "[TEST] payload candidates=#{payload['candidates']&.size || 0}"

  # 5) Mapper 直接建出 Entity
  entity = LingoBeats::Gemini::MaterialMapper.build_entity(
    payload,
    song_id: song_id,
    level: level
  )

  # 6) 基本檢查：型別與欄位
  assert!(entity.is_a?(LingoBeats::Entity::Material), '回傳不是 LingoBeats::Entity::Material')
  assert!(entity.song_id == song_id, 'song_id 不一致')
  assert!(entity.level == level,     'level 不一致')
  assert!(entity.content.is_a?(String) && !entity.content.empty?, 'content 不是字串或為空')

  # 7) 解析 content JSON，驗證關鍵鍵值存在
  parsed = JSON.parse(entity.content, symbolize_names: true)
  assert!(parsed.is_a?(Hash), 'content 解析後不是 Hash')

  # 預期鍵
  %i[summary vocabulary phrases].each do |k|
    assert!(parsed.key?(k), "缺少鍵：#{k}")
  end
  assert!(parsed[:summary].is_a?(String), 'summary 型別錯誤')
  assert!(parsed[:vocabulary].is_a?(Array), 'vocabulary 型別錯誤')
  assert!(parsed[:phrases].is_a?(Array), 'phrases 型別錯誤')

  # 8) 輸出示例
  puts '[TEST] ✅ entity 建立成功'
  puts "[TEST] entity.class = #{entity.class}"
  puts "[TEST] entity.song_id = #{entity.song_id}"
  puts "[TEST] entity.level   = #{entity.level}"
  puts '[TEST] material preview (parsed content):'
  preview = {
    summary: parsed[:summary],
    vocabulary_sample: parsed[:vocabulary].first(2),
    phrases_sample: parsed[:phrases].first(2)
  }
  puts JSON.pretty_generate(preview)
rescue StandardError => e
  warn "[TEST] ❌ error: #{e.class} - #{e.message}"
  warn e.backtrace&.first(8)&.join("\n")
  exit 1
end

puts '[TEST] done.'

saved = LingoBeats::Repository::Materials.create(entity)
fetched = LingoBeats::Repository::Materials.find_by_song_id(saved.song_id)

puts '[TEST] saved.id? (orm)' # orm 轉回 entity 不含 id，僅確認無例外
puts "[TEST] fetched.level=#{fetched.level}"
puts "[TEST] fetched.content.size=#{fetched.content.size}"
