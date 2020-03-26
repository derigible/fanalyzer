# frozen_string_literal: true

module DatabaseConnections
  class Base
    def initialize(database_name)
      @db_name = database_name
    end

    def create!(_opts)
      raise 'Must implement create'
    end

    def conn
      raise 'Must implement conn'
    end

    def db_exists?
      raise 'Must implement db_exists?'
    end
  end
end
