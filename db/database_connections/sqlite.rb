# frozen_string_literal: true

require 'sqlite3'
require_relative 'base'

module DatabaseConnections
  class Sqlite < Base
    def create!(opts = {})
      File.delete(appended_db) if File.exist?(appended_db) && opts[:force]

      SQLite3::Database.new(appended_db)
    end

    def conn
      @conn = begin
        raise 'Database does not exist.' unless File.exist?(appended_db)

        Sequel.connect("sqlite://#{appended_db}")
      end
    end

    def db_exists?
      File.exist?(appended_db)
    end

    private

    def appended_db
      @db_name.split('.').last != '.sqlite3' ? @db_name + '.sqlite3' : @db_name
    end
  end
end
