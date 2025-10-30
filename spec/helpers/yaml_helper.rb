# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module YamlHelper
  # 將 Entity 陣列轉成純 Ruby Hash 結構（可用於測試）
  def self.to_hash_array(entities, include_lyric: true)
    entities.map do |entity|
      data_hash = entity.to_attr_hash.dup
      data_hash[:lyric] = nil if include_lyric


      data_hash[:singers] = entity[:singers].map do |sub_entity|
        sub_entity.respond_to?(:to_attr_hash) ? sub_entity.to_attr_hash : sub_entity
      end

      data_hash
    end
  end

  # 將結果輸出為 .yml 檔案
  def self.export_yaml(entities, file_path:, include_lyric: true)
    data = to_hash_array(entities, include_lyric:)
    dir = File.dirname(file_path)
    Dir.mkdir(dir) unless Dir.exist?(dir)
    File.write(file_path, data.to_yaml)
    puts "✅ Exported #{data.size} records to #{file_path}"
  end
end