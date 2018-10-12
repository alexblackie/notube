$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "notube"

Notube.create_database
run Notube::Application
