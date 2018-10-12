require "sinatra"
require "sqlite3"
require "pry" if development?

require "notube/database"
require "notube/models/video"
require "notube/models/channel"
require "notube/application"
