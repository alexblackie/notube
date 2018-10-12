module Notube
  class Fetch

    YOUTUBE_API_URL = "https://www.googleapis.com/".freeze
    YOUTUBE_API_PREFIX = "/youtube/v3".freeze
    YOUTUBE_DL = "/usr/bin/youtube-dl".freeze

    def initialize
      @db = Application.settings.db
      @storage_path = Application.settings.storage_path
      @youtube_api_key = Application.settings.youtube_api_key
    end

    # Import channel to library.
    #
    # @param channel_url [String] the full URL to the channel webpage.
    # @return [Notube::Models::Channel|nil]
    def add_channel(channel_url)
      existing = @db.find_by(Models::Channel, "url", channel_url)
      return existing unless existing.nil?

      opts = {
        part: "snippet,brandingSettings,contentDetails",
        key: @youtube_api_key
      }

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
        return
      end

      external_id = resp["items"].first["id"]
      title = resp["items"].first["snippet"]["title"]
      playlist_id = resp["items"].first["contentDetails"]["relatedPlaylists"]["uploads"]
      @db.execute("insert into channels (external_id, name, url, playlist_id) values (?, ?, ?, ?)",
                  external_id, title, channel_url, playlist_id)

      download_image(
        local: "#{ @storage_path }/#{ external_id }.banner.jpg",
        remote: resp["items"].first["brandingSettings"]["image"]["bannerImageUrl"]
      )

      download_image(
        local: "#{ @storage_path }/#{ external_id }.jpg",
        remote: resp["items"].first["snippet"]["thumbnails"]["high"]["url"]
      )

      @db.find_by(Models::Channel, "external_id", external_id)
    end

    # Get the last 25 videos for a channel and add them to the library (does not
    # download them).
    #
    # @param channel [Notube::Models::Channel]
    def add_videos_for_channel(channel)
      resp = api.get(api_path("playlistItems"), {
        playlistId: channel.playlist_id,
        part: "snippet",
        maxResults: 25,
        key: @youtube_api_key
      })
      resp = JSON.parse(resp.body)

      resp["items"].each do |v|
        snippet = v["snippet"]

        next if @db.find_by(Models::Video, "external_id", snippet["resourceId"]["videoId"])

        storage_dir = File.join(@storage_path, channel.external_id)
        FileUtils.mkdir_p(storage_dir)

        # None of these are guaranteed to exist
        thumb = snippet["thumbnails"]["maxres"] ||
                snippet["thumbnails"]["standard"] ||
                snippet["thumbnails"]["high"] ||
                snippet["thumbnails"]["medium"] ||
                snippet["thumbnails"]["default"]

        download_image(
          local: "#{ storage_dir }/#{ snippet["resourceId"]["videoId"] }.jpg",
          remote: thumb["url"]
        )

        @db.execute("insert into videos (external_id,title,description,channel_id,published_at) values(?, ?, ?, ?, ?)",
                   snippet["resourceId"]["videoId"], snippet["title"], snippet["description"], channel.id, snippet["publishedAt"])
      end
    end

    # Download a video, download its metadata, and add it to our library.
    #
    # @param video [Notube::Models::Video] the video to download
    def download_video(video)
      storage_dir = File.join(@storage_path, video.channel.external_id)
      FileUtils.mkdir_p(storage_dir)

      Dir.chdir(storage_dir) do
        cmd(*%W[#{YOUTUBE_DL} --id -f 248+251/bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4' #{ video.external_id }])
      end

      @db.execute("update videos set downloaded_at = CURRENT_TIMESTAMP where id = ?", video.id)
    end

    private

    def api
      Faraday.new(url: YOUTUBE_API_URL) do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
    end

    def api_path(path)
      [YOUTUBE_API_PREFIX, path].join("/")
    end

    def cmd(*args)
      puts args.join(" ")
      ret = system(*args)
      raise "command failed: #{args.inspect}" unless ret
    end

    def download_image(local: , remote: )
      return if File.exist?(local)

      File.open(local, "wb") do |local_img|
        open(remote, "rb"){|remote_img| local_img.write(remote_img.read) }
      end
    end

  end
end
