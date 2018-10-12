$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "notube"

Notube::Application.settings.db.create_database
run Notube::Application
