# frozen_string_literal: true

module DatabaseConnections
  class Base
    def initialize(db_name)
      @db_name = db_name
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

    private

    attr_reader :db_name
  end
end
