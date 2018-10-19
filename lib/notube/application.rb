module Notube
  class Application < Sinatra::Base

    set :db, Notube::Database.new
    set :public_folder, Proc.new { File.join(root, "..", "..", "static") }
    set :static_cache_control, [:public, max_age: 3600]
    set :youtube_api_key, nil
    set :youtube_channels, []
    set :storage_path, "static/data"
    set :per_page, 30

    CONFIG_KEYS = %i[
      youtube_api_key
      youtube_channels
      storage_path
    ].freeze

    def self.load_config_file(filename)
      config = YAML.load_file(config_path).freeze

      CONFIG_KEYS.each do |key|
        next unless config.has_key?(key)
        set key, config[key]
      end
    end

    helpers do
      def static_digest(static_path)
        abspath = File.join(settings.public_folder, static_path)
        data = File.read(abspath)
        "#{static_path}?#{Digest::MD5.hexdigest(data)}"
      end
    end

    get "/" do
      @page_class = "page-home"
      @channels = settings.db.execute("select id,external_id,name from channels")
      @videos = settings.db.select(Models::Video, <<-SQL)
        select * from videos where watched_at is null order by videos.published_at desc limit #{settings.per_page}
      SQL

      erb :next
    end

    get "/recent" do
      @page_class = "page-recent"
      @channels = settings.db.execute("select id,external_id,name from channels")
      @videos = settings.db.select(Models::Video, <<-SQL)
        select * from videos order by videos.published_at desc limit #{settings.per_page}
      SQL

      erb :recent
    end

    get "/videos/:id" do
      @channels = settings.db.execute("select id,external_id,name from channels")

      @video = settings.db.select(Models::Video, <<-SQL, params[:id]).first
        select * from videos where videos.id = ?
      SQL

      settings.db.execute("update videos set watched_at = CURRENT_TIMESTAMP where id = ?", params[:id])

      erb :video
    end

    get "/channels/:id" do
      params[:before] ||= "CURRENT_TIMESTAMP"

      @channels = settings.db.execute("select id,external_id,name from channels")
      @channel = settings.db.find(Models::Channel, params[:id])
      @videos = settings.db.select(Models::Video, <<-SQL, params[:id], params[:before])
        select * from videos
        where videos.channel_id = ? and published_at < ?
        order by published_at desc limit #{settings.per_page}
      SQL

      @next_offset = @videos.last.published_at unless @videos.empty?

      erb :channel
    end

    get "/download/:id" do
      video = settings.db.find(Models::Video, params[:id])
      Notube::Fetch.new.download_video(video)
      JSON.generate({ ok: true })
    end

    post "/refresh" do
      fetch = Notube::Fetch.new

      Notube::Application.settings.youtube_channels.map do |channel_url|
        fetch.add_channel(channel_url)
      end.each do |channel|
        fetch.add_videos_for_channel(channel)
      end

      status(200)
    end

  end
end
