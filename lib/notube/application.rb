module Notube
  class Application < Sinatra::Base

    CONFIG = YAML.load_file(File.join(root, "..", "..", "config.yml")).freeze

    set :db, Notube::Database.new
    set :public_folder, Proc.new { File.join(root, "..", "..", "static") }
    set :youtube_api_key, CONFIG["youtube_api_key"]
    set :youtube_channels, CONFIG["youtube_channels"]
    set :storage_path, CONFIG["storage_path"]

    get "/" do
      @channels = settings.db.execute("select id,external_id,name from channels")
      @videos = settings.db.execute("select * from videos " +
                  "order by videos.published_at desc limit 10").map do |row|
                    Models::Video.new(row)
                  end

      erb :home
    end

    get "/videos/:id" do
      @channels = settings.db.execute("select id,external_id,name from channels")

      row = settings.db.execute("select * from videos " +
              "where videos.id = ?", params[:id]).first
      @video = Models::Video.new(row)

      settings.db.execute("update videos set watched_at = CURRENT_TIMESTAMP where id = ?", params[:id])

      erb :video
    end

    get "/channels/:id" do
      params[:before] ||= "CURRENT_TIMESTAMP"

      @channels = settings.db.execute("select id,external_id,name from channels")
      @channel = settings.db.find(Models::Channel, params[:id])
      video_rows = settings.db.execute("select * from videos " +
        "inner join channels on videos.channel_id = channels.id " +
        "where videos.channel_id = ? and published_at < ? " +
        "order by published_at desc limit 25", params[:id], params[:before])
      @videos = video_rows.map{|row| Models::Video.new(row) }

      @next_offset = @videos.last.published_at unless @videos.empty?

      erb :channel
    end

    get "/download/:id" do
      video = settings.db.find(Models::Video, params[:id])
      Notube::Fetch.new.download_video(video)
      JSON.generate({ ok: true })
    end

  end
end
