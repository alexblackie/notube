require "sinatra"
require "yaml"
require "open-uri"
require "faraday"
require "sqlite3"
require "pry" if development?

require "notube/database"
require "notube/model"
require "notube/models/video"
require "notube/models/channel"
require "notube/fetch"
require "notube/application"
