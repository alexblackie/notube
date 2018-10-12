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
      find_by(model, :id, id)
    end

    # Find a model by the given field.
    #
    # @param model [Class] the PORO object to hold the row data
    # @param field [String] the column to filter on
    # @param value [String] the value of the column to find
    # @return [model|nil] an instance of <model> with the row data; nil if not found.
    def find_by(model, field, value)
      result = @db.query("select * from #{ model::TABLE_NAME } where #{ model::TABLE_NAME }.#{ field } = ? limit 1", value)
      row = result.next_hash
      return nil if row.nil?
      model.new(row)
    end

    # Fall through to SQLite directly for complex queries.
    def execute(*args)
      @db.execute(*args)
    end

    def select(model, *args)
      query(*args).map do |row|
        model.new(row)
      end
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
