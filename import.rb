$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "notube"

Notube::Application.settings.db.create_database

fetch = Notube::Fetch.new

Notube::Application.settings.youtube_channels.map do |channel_url|
  fetch.add_channel(channel_url)
end.each do |channel|
  fetch.add_videos_for_channel(channel)
end
