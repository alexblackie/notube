require "sinatra"
require "sqlite3"
require "pry" if development?

require "notube/database"
require "notube/models/video"
require "notube/models/channel"
require "notube/application"

module Notube
  def self.create_database
    db = Notube::Application.settings.db

    if db.execute("SELECT name FROM sqlite_master").empty?
      warn "Creating database..."
      schema_statements = File.read("schema.sql")
      db.execute_batch(schema_statements)
    end
  end
end
