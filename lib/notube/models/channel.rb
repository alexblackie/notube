module Notube
  module Models
    class Channel

      TABLE_NAME = "channels".freeze

      attr_reader :id, :external_id, :name, :url, :playlist_id

      # @param row [Array] the SQL result row
      def initialize(row)
        @id = row[0]
        @external_id = row[1]
        @url = row[2]
        @name = row[3]
        @playlist_id = row[4]
      end

    end
  end
end
