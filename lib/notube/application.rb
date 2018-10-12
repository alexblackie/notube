module Notube
  class Application < Sinatra::Base

    set :db, Notube::Database.new
    set :public_folder, Proc.new { File.join(root, "..", "..", "static") }

    get "/" do
      @channels = settings.db.execute("select id,external_id,name from channels")
      @videos = settings.db.select(Models::Video, <<-SQL)
        select * from videos order by videos.published_at desc limit 10
      SQL

      erb :home
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
        inner join channels on videos.channel_id = channels.id
        where videos.channel_id = ? and published_at < ?
        order by published_at desc limit 25
      SQL

      @next_offset = @videos.last.published_at unless @videos.empty?

      erb :channel
    end

  end
end
