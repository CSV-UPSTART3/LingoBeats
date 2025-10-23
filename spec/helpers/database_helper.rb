# frozen_string_literal: true

# Helper to clean database during test runs
module DatabaseHelper
  def self.wipe_database
    # Ignore foreign key constraints when wiping tables
    LingoBeats::App.db.run('PRAGMA foreign_keys = OFF')
    # ORM
    # ...
    LingoBeats::App.db.run('PRAGMA foreign_keys = ON')
  end
end
