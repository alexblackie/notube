module Notube
  class Database

    def initialize
      environment = ENV.fetch("RACK_ENV", "development")
      @db = SQLite3::Database.new("#{ environment }.db")
    end

    # Find a model by its ID.
    #
    # @param model [Class] the PORO object to give the raw row data to
    # @param id [Integer] the ID to find
    # @return [model|nil] an instance of <model> with the row data; nil if not found.
    def find(model, id)
      find_by(model, id: id)
    end

    # Find a model by the given field.
    #
    # @param model [Class] the PORO object to hold the row data
    # @param attributes [Hash] the attributes to filter on
    # @return [model|nil] an instance of <model> with the row data; nil if not found.
    def find_by(model, attributes)
      values = []
      conditions = attributes.map do |field, value|
        values << value
        "#{ model::TABLE_NAME }.#{ field } = ?"
      end.join(" AND ")

      result = @db.query("select * from #{ model::TABLE_NAME } where #{ conditions } limit 1", *values)
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

    def create_database
      if @db.execute("SELECT name FROM sqlite_master").empty?
        warn "Creating database..."
        schema_statements = File.read("schema.sql")
        @db.execute_batch(schema_statements)
      end
    end
  end
end
