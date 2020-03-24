# frozen_string_literal: true

require 'sqlite3'
require_relative 'base'

module DatabaseConnections
  class Sqlite < Base
    def create!(opts = {})
      File.delete(db_name) if File.exist?(db_name) && opts[:force]
      db_name += '.db' if db_name.split('.').last != '.db'
      SQLite3::Database.new(db_name)
    end

    def conn
      @conn = begin
        raise 'Database does not exist.' unless File.exist?(db_name)

        Sequel.connect("sqlite://#{db_name}")
      end
    end

    def db_exists?
      File.exist?(db_name)
    end
  end
end
