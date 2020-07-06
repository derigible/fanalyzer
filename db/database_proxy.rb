# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string/inflections'
require 'active_support/inflector'

require_relative 'constants'
require_relative 'database_connections/sqlite'
require_relative 'database_connections/postgres'

# Proxy object for a given database
class DatabaseProxy
  attr_reader :db_name, :connection

  def initialize(db_name, type)
    @db_name = db_name
    @type = type
    @connection = if type == 'sqlite'
                    DatabaseConnections::Sqlite.new(db_name)
                  else
                    DatabaseConnections::Postgres.new(db_name)
                  end
    load_models
  end

  def create_database(options)
    unless !check_db(options) || options[:force]
      puts "Cannot create #{db_name} as it already exists!"
      puts 'If you want to drop the database and recreate, use the -f flag'
      return
    end
    connection.create!(options)
  end

  def check_db(opts = {})
    unless db_exists?
      puts 'Database does not exist'
      return false
    end
    check_migrations(opts)
  end

  def run_migrations
    return unless check_db

    Sequel.extension :migration
    Sequel::Migrator.run(conn, File.join(DB_CONFIG_PATH, 'migrations/'))
    puts 'migrations complete'
  end

  def check_migrations(opts)
    return true unless opts[:migrated]

    Sequel.extension :migration
    result = Sequel::Migrator.is_current?(
      conn, File.join(DB_CONFIG_PATH, 'migrations/')
    )
    puts('Database not migrated to latest') unless result
    result
  end

  def model(model)
    conn
    require_relative "models/#{model}"
    "Models::#{model.to_s.camelize}".constantize
  end

  def load_models
    %i[servicer category transaction label].each { |m| model(m) }
  end

  delegate :create!, to: :connection
  delegate :conn, to: :connection
  delegate :db_exists?, to: :connection
end
