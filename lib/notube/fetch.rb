module Notube
  class Fetch

    # @param youtube_api [Class] the Youtube API class to use
    def initialize(youtube_api: YoutubeApi)
      @db = Application.settings.db
      @storage_path = Application.settings.storage_path
      @youtube_api = youtube_api.new(api_key: Application.settings.youtube_api_key)
    end

    # Import channel to library.
    #
    # @param channel_url [String] the full URL to the channel webpage.
    # @return [Notube::Models::Channel|nil]
    def add_channel(channel_url)
      existing = @db.find_by(Models::Channel, url: channel_url)
      return existing unless existing.nil?

      channel_url_id = channel_url.split("/").last
      channel = if channel_url.match?(/user\//)
        @youtube_api.get_channel(username: channel_url_id)
      else
        @youtube_api.get_channel(id: channel_url_id)
      end


      unless channel
        warn "Could not find channel #{ channel_url }. Skipping"
        return
      end

      external_id = channel["id"]
      title = channel["snippet"]["title"]
      playlist_id = channel["contentDetails"]["relatedPlaylists"]["uploads"]
      @db.execute("insert into channels (external_id, name, url, playlist_id) values (?, ?, ?, ?)",
                  [external_id, title, channel_url, playlist_id])

      download_image(
        local: "#{ @storage_path }/#{ external_id }.banner.jpg",
        remote: channel["brandingSettings"]["image"]["bannerImageUrl"]
      )

      download_image(
        local: "#{ @storage_path }/#{ external_id }.jpg",
        remote: channel["snippet"]["thumbnails"]["high"]["url"]
      )

      @db.find_by(Models::Channel, external_id: external_id)
    end

    # Get the last 25 videos for a channel and add them to the library (does not
    # download them).
    #
    # @param channel [Notube::Models::Channel]
    def add_videos_for_channel(channel)
      @youtube_api.get_videos(channel: channel).each do |v|
        snippet = v["snippet"]

        next if @db.find_by(Models::Video, external_id: snippet["resourceId"]["videoId"])

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

        @db.execute(<<-SQL, [snippet["resourceId"]["videoId"], snippet["title"], snippet["description"], channel.id, snippet["publishedAt"]])
          insert into videos (
            external_id, title, description, channel_id, published_at
          ) values(?, ?, ?, ?, ?)
        SQL
      end
    end

    # Download a video, download its metadata, and add it to our library.
    #
    # @param video [Notube::Models::Video] the video to download
    def download_video(video)
      storage_dir = File.join(@storage_path, video.channel.external_id)
      FileUtils.mkdir_p(storage_dir)

      Dir.chdir(storage_dir) do
        cmd(*%W[#{YOUTUBE_DL} --id -f 248+251/bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4' -- #{ video.external_id }])
      end

      @db.execute("update videos set downloaded_at = CURRENT_TIMESTAMP where id = ?", video.id)
    end

    private

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
