require "yaml"
require "json"
require "open-uri"
require "faraday"
require "sqlite3"

$LOAD_PATH.unshift "#{__dir__}/lib"
require "notube"
Notube.create_database

require "pry"

# ------------------------------------------------------------------------------
# Constants and Configuration
# ------------------------------------------------------------------------------

CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), "config.yml")).freeze
DB = SQLite3::Database.new("library.db")

YOUTUBE_API_URL = "https://www.googleapis.com/".freeze
YOUTUBE_API_PREFIX = "/youtube/v3".freeze
YOUTUBE_DL = "/usr/bin/youtube-dl".freeze


# ------------------------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------------------------
def api_path(path)
  [YOUTUBE_API_PREFIX, path].join("/")
end

# ------------------------------------------------------------------------------
# Channel content downloading
# ------------------------------------------------------------------------------
api = Faraday.new(url: YOUTUBE_API_URL) do |faraday|
  faraday.request :url_encoded
  faraday.adapter Faraday.default_adapter
end

def cmd(*args)
  puts args.join(" ")
  ret = system(*args)
  raise "command failed: #{args.inspect}" unless ret
end

CONFIG["youtube_channels"].each do |channel_url|
  channel_row = DB.execute("select id,external_id,name from channels where url = ?", channel_url)

  if channel_row.empty?
    puts "No existing data for #{ channel_url }. Fetching..."

    opts = {
      part: "snippet,brandingSettings",
      key: CONFIG["youtube_api_key"]
    }

    # XXX The param name needs to be different depending on if this is a user
    # named page or a raw channel permalink.
    channel_url_id = channel_url.split("/").last
    if channel_url.match?(/\/user\//)
      opts[:forUsername] = channel_url_id
    else
      opts[:id] = channel_url_id
    end

    resp = api.get(api_path("channels"), opts)
    resp = JSON.parse(resp.body)

    if resp["items"].empty?
      warn "Could not find channel #{ channel_url }. Skipping"
      next
    end

    external_id = resp["items"].first["id"]
    title = resp["items"].first["snippet"]["title"]
    DB.execute("insert into channels (external_id, name, url) values (?, ?, ?)", external_id, title, channel_url)

    File.open("#{ CONFIG["storage_path"] }/#{ external_id }.banner.jpg", "wb") do |banner|
      open(resp["items"].first["brandingSettings"]["image"]["bannerImageUrl"], "rb") do |remote_image|
        banner.write(remote_image.read)
      end
    end unless File.exist?("#{ CONFIG["storage_path"] }/#{ external_id }.banner.jpg")

    File.open("#{ CONFIG["storage_path"] }/#{ external_id }.jpg", "wb") do |thumb|
      open(resp["items"].first["snippet"]["thumbnails"]["high"]["url"], "rb") do |remote_image|
        thumb.write(remote_image.read)
      end
    end unless File.exist?("#{ CONFIG["storage_path "] }/#{ external_id }.jpg")

    channel_row = DB.execute("select id,external_id,name from channels where external_id = ?", external_id)
  end

  channel_id = channel_row.first.first
  external_id = channel_row.first[1]

  storage_dir = File.join(CONFIG["storage_path"], external_id)

  FileUtils.mkdir_p(storage_dir)
  Dir.chdir(storage_dir) do
    puts "Updating #{ channel_url }"
    cmd(*%W[#{YOUTUBE_DL} --id -w --write-thumbnail -f 248+251/bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4' --download-archive ../#{ external_id }.index #{ channel_url }])
  end

  video_ids = File.read("#{ CONFIG["storage_path"] }/#{ external_id }.index").lines.map{|l| l.split.last}
  DB.execute("select external_id from videos where channel_id = ?", channel_id) do |row|
    # TODO performance??
    video_ids.delete(row.first)
  end

  import_count = video_ids.reduce(0) do |acc, video_id|
    resp = api.get(api_path("videos"), {
      part: "snippet",
      id: video_id,
      key: CONFIG["youtube_api_key"]
    })
    resp = JSON.parse(resp.body)
    v = resp["items"].first

    DB.execute("insert into videos (external_id,title,description,channel_id,published_at) values(?, ?, ?, ?, ?)",
               video_id, v["snippet"]["title"], v["snippet"]["description"], channel_id, v["snippet"]["publishedAt"])

    acc += 1
  end

  puts "Imported #{ import_count } videos for #{ channel_row.first[2] }"

end
