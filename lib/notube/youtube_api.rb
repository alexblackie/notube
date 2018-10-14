module Notube
  class YoutubeApi

    YOUTUBE_API_URL = "https://www.googleapis.com/".freeze
    YOUTUBE_API_PREFIX = "/youtube/v3".freeze
    YOUTUBE_DL = "/usr/bin/youtube-dl".freeze

    # @param api_key [String] API key for Youtube Data API V3
    def initialize(api_key: )
      @api_key = api_key
    end

    # Get details about a channel by username or ID.
    #
    # @param username [String] "pretty" username. eg, "maangchi"
    # @param id [String] machine-generated ID. eg., "UC8gFadPgK2r1ndqLI04Xvvw"
    # @return [Hash] parsed response JSON of the channel resource
    def get_channel(username: nil, id: nil)
      # username & id are mutally exclusive, and one is required
      raise ArgumentError if !(username || id) || (username && id)

      opts = { part: "snippet,brandingSettings,contentDetails" }
      opts[:forUsername] = username if username
      opts[:id] = id if id

      get(path: "channels", opts: opts)["items"].first
    end

    # Get the latest $n videos for the given channel.
    #
    # @param channel [Notube::Models::Channel]
    # @param limit [Integer] number of videos to return; default 25; max 50
    # @return [Hash] parsed JSON response; array of playlistItem resources
    def get_videos(channel: , limit: 25)
      get(
        path: "playlistItems",
        opts: {
          playlistId: channel.playlist_id,
          part: "snippet",
          maxResults: 25
        }
      )["items"]
    end

    # Fetch (a) resource(s) from the API.
    #
    # @param path [String] relative path for the endpoint. eg., "channels"
    # @param opts [Hash<Symbol,String|Integer>] request parameters
    # @return [Hash] parsed response JSON
    def get(path: , opts: )
      path = api_path(path)
      opts = { key: @api_key }.merge(opts)
      resp = request.get(path, opts)
      JSON.parse(resp.body)
    end

    private

    def request
      Faraday.new(url: YOUTUBE_API_URL) do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
    end

    def api_path(path)
      [YOUTUBE_API_PREFIX, path].join("/")
    end

  end
end
