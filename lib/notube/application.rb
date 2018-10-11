module Notube
  class Application < Sinatra::Base

    set :db, SQLite3::Database.new("library.db")
    set :public_folder, Proc.new { File.join(root, "..", "..", "static") }

    get "/" do
      @channels = settings.db.execute("select id,external_id,name from channels")

      columns = [
        "videos.id", "videos.external_id", "videos.title", "channels.id",
        "channels.external_id", "channels.name"
      ].join(",")
      @videos = settings.db.execute("select #{ columns } from videos " +
                  "inner join channels on videos.channel_id = channels.id " +
                  "order by videos.created_at desc limit 10")

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
      erb :video
    end

  end
end
