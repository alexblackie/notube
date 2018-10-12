module Notube
  module Models
    class Video

      TABLE_NAME = "videos".freeze

      attr_reader :id, :external_id, :title, :description, :channel_id,
                  :watched_at, :published_at

      # @param row [Array] the SQL result row
      def initialize(row)
        @id = row[0]
        @external_id = row[1]
        @title = row[2]
        @description = row[3]
        @channel_id = row[4]
        @watched_at = row[5]
        @published_at = row[6]
      end

      # Has this video been watched?
      #
      # @return [Boolean] true if watched_at has been set
      def watched?
        !@watched_at.nil?
      end

      # Load the Channel object for this video.
      # @return [Notube::Models::Channel]
      def channel
        @channel ||= Notube::Application.settings.db.find(Channel, @channel_id)
      end

    end
  end
end
