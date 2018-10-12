module Notube
  module Models
    class Channel < Model

      TABLE_NAME = "channels".freeze

      attr_accessor :id, :external_id, :name, :url

    end
  end
end
