$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "notube"

Notube::Application.load_config_file("#{__dir__}/config.yml")
Notube::Application.settings.db.create_database
run Notube::Application
