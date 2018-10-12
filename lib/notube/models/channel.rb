module Notube
  module Models
    class Channel

      TABLE_NAME = "channels".freeze

      attr_accessor :id, :external_id, :name, :url

      # @param row [Hash] the SQL result row
      def initialize(attributes)
        attributes.each_pair do |k, v|
          public_send("#{k}=", v)
        end
      end

    end
  end
end
