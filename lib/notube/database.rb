module Notube
  class Database

    DATABASE_NAME = "library.db".freeze

    def initialize
      @db = SQLite3::Database.new(DATABASE_NAME)
    end

    # Find a model by its ID.
    #
    # @param model [Class] the PORO object to give the raw row data to
    # @param id [Integer] the ID to find
    # @return [model|nil] an instance of <model> with the row data; nil if not found.
    def find(model, id)
      result = @db.query("select * from #{ model::TABLE_NAME } where #{ model::TABLE_NAME }.id = ? limit 1", id)
      row = result.next_hash
      return nil if row.nil?
      model.new(row)
    end

    # Fall through to SQLite directly for complex queries.
    def execute(*args)
      @db.execute(*args)
    end

    def query(*args)
      return enum_for(:query, *args) unless block_given?
      result = @db.query(*args)
      result.each_hash do |row|
        yield row
      end
    end
  end
end
