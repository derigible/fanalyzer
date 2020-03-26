# frozen_string_literal: true

require 'pg'
require_relative 'base'
require_relative '../constants'

module DatabaseConnections
  class Postgres < Base
    def create!(opts = {})
      postgres_db.execute("DROP DATABASE IF EXISTS #{@db_name}") if opts[:force]
      postgres_db.execute "CREATE DATABASE #{@db_name}"
    end

    def conn
      @conn = begin
        config = @db_name ? DB_CONFIG.merge('database' => @db_name) : DB_CONFIG
        Sequel.postgres(config)
      end
    end

    def db_exists?
      out = postgres_db[
        'SELECT 1 where EXISTS(
          select datname from pg_catalog.pg_database
          where lower(datname) = lower(?)
        );',
        @db_name
      ]
      !out.first.nil?
    end

    private

    def postgres_db
      @postgres_db ||= Sequel.postgres(DB_CONFIG.merge('database' => 'postgres'))
    end
  end
end
