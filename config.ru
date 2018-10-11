$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "notube"

run Notube::Application
