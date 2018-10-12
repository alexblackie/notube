module Notube
  module Models
    class Video < Model

      TABLE_NAME = "videos".freeze

      attr_accessor :id, :external_id, :title, :description, :channel_id,
                    :watched_at, :published_at, :downloaded_at, :url, :name, :playlist_id

      # Has this video been watched?
      #
      # @return [Boolean] true if watched_at has been set
      def watched?
        !@watched_at.nil?
      end

      # Has this video been downloaded?
      #
      # @return [Boolean] true if downloaded_at has been set
      def downloaded?
        !@downloaded_at.nil?
      end

      # Load the Channel object for this video.
      # @return [Notube::Models::Channel]
      def channel
        @channel ||= Notube::Application.settings.db.find(Channel, @channel_id)
      end

    end
  end
end
