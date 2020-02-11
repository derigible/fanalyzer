# frozen_string_literal: true

DB_CONFIG_PATH = File.join(File.dirname(__FILE__), '..', 'db')
DB_CONFIG = YAML.load_file(
  File.join(DB_CONFIG_PATH, 'config.yml')
)

# Proxy object for a given database
class DatabaseProxy
  attr_reader :db_name, :postgres_db

  def initialize(db_name, postgres_db)
    @db_name = db_name
    @postgres_db = postgres_db
  end

  def create_database(options)
    unless !check_db(options) || options[:force]
      puts "Cannot create #{db_name} as it already exists!"
      puts 'If you want to drop the database and recreate, use the -f flag'
      return
    end
    postgres_db.execute("DROP DATABASE IF EXISTS #{db_name}") if options[:force]
    postgres_db.execute "CREATE DATABASE #{db_name}"
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

  private

  def conn
    @conn ||= begin
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
end
