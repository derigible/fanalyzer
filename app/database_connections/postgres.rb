# frozen_string_literal: true

require 'pg'
require_relative 'base'
require_relative '../constants'

module DatabaseConnections
  class Postgres < Base
    def create!(opts = {})
      File.delete(db_name) if File.exist?(db_name) && opts[:force]
      db_name += '.db' if db_name.split('.').last != '.db'
      SQLite3::Database.new(db_name)
    end

    def conn
      @conn = begin
        config = db_name ? DB_CONFIG.merge('database' => db_name) : DB_CONFIG
        Sequel.postgres(config)
      end
    end

    def db_exists?
      out = postgres_db[
        'SELECT 1 where EXISTS(
          select datname from pg_catalog.pg_database
          where lower(datname) = lower(?)
        );',
        db_name
      ]
      !out.first.nil?
    end

    private

    def postgres_db
      @postgres_db ||= Sequel.postgres(DB_CONFIG.merge('database' => 'postgres'))
    end
  end
end
