module Notube
  class Model

    # @param row [Hash] the SQL result row
    def initialize(attributes)
      attributes.each_pair do |k, v|
        public_send("#{k}=", v)
     end
    end
  end
end
