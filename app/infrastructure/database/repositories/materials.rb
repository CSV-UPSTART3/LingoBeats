# frozen_string_literal: true

require_relative '../orm/material_orm'
require_relative '../../gemini/mappers/material_mapper'
require_relative '../../../domain/materials/entities/material'

module LingoBeats
  module Repository
    # Repository for Material Entities
    class Materials
      # 取多筆
      def self.all
        rows = LingoBeats::Database::MaterialOrm.all
        rebuild_many(rows)
      end

      def self.latest(limit = 20)
        LingoBeats::Database::MaterialOrm.reverse_order(:id)
                                         .limit(limit).all
                                         .map { |r| rebuild_entity(r) }
      end

      # 查一筆
      def self.find_id(id)
        rec = LingoBeats::Database::MaterialOrm.first(id: id)
        rebuild_entity(rec)
      end

      def self.find_by_song_id(song_id)
        rec = LingoBeats::Database::MaterialOrm.where(song_id: song_id)
                                               .order(Sequel.desc(:id)).first
        rebuild_entity(rec)
      end

      # 新增（由 Domain Entity 建立）
      def self.create(entity)
        rec = LingoBeats::Database::MaterialOrm.create(
          song_id: entity.song_id,
          level: entity.level,
          content: entity.content # JSON 字串
        )
        rebuild_entity(rec)
      end

      # --- helpers ---
      def self.rebuild_many(db_records)
        Array(db_records).map { |r| rebuild_entity(r) }
      end
      private_class_method :rebuild_many

      def self.rebuild_entity(rec)
        return nil unless rec

        LingoBeats::Entity::Material.new(
          song_id: rec.song_id,
          level: rec.level,
          content: rec.content
        )
      end
      private_class_method :rebuild_entity
    end
  end
end
