module Notube
  class Application < Sinatra::Base

    set :db, SQLite3::Database.new("library.db")
    set :public_folder, Proc.new { File.join(root, "..", "..", "static") }

    get "/" do
      @channels = settings.db.execute("select id,external_id,name from channels")
      @videos = settings.db.execute("select * from videos " +
                  "inner join channels on videos.channel_id = channels.id " +
                  "order by videos.published_at desc limit 10")

      erb :home
    end

    get "/videos/:id" do
      @channels = settings.db.execute("select id,external_id,name from channels")

      columns = [
        "videos.id", "videos.external_id", "videos.title", "videos.description",
        "channels.id", "channels.external_id", "channels.name"
      ].join(",")
      @video = settings.db.execute("select #{ columns } from videos " +
                 "inner join channels on videos.channel_id = channels.id " +
                 "where videos.id = ?", params[:id]).first

      settings.db.execute("update videos set watched_at = CURRENT_TIMESTAMP where id = ?", params[:id])

      erb :video
    end

    get "/channels/:id" do
      params[:before] ||= "CURRENT_TIMESTAMP"

      @channels = settings.db.execute("select id,external_id,name from channels")
      @channel = settings.db.execute("select * from channels where id = ?", params[:id])
      @videos = settings.db.execute("select * from videos " +
        "inner join channels on videos.channel_id = channels.id " +
        "where videos.channel_id = ? and published_at < ? " +
        "order by published_at desc limit 25", params[:id], params[:before])
      @next_offset = @videos.last[6] unless @videos.empty?

      erb :channel
    end

  end
end
