module Notube
  class Model

    # @param row [Hash] the SQL result row
    def initialize(attributes)
      attributes.each_pair do |k, v|
        public_send("#{k}=", v)
     end
    end

    def display_timestamp(field)
      return unless ts = public_send(field)
      ts = DateTime.parse(ts)
      format_string = ts.year == Date.today.year ? "%B %d %H:%M" : "%B %d %Y %H:%M"
      ts.strftime(format_string)
    end

  end
end
