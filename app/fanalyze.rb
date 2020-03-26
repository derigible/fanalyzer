# frozen_string_literal: true

require 'byebug'
require_relative './database_proxy'
require_relative 'interactive'

# Main entry to analyzer
class Fanalyze < Thor
  desc 'create_db', 'create a new transactions database'
  option(
    :force,
    type: :boolean,
    aliases: :f,
    desc: 'Force the creation. WARNING: will destroy previous database!'
  )
  option(
    :migrate,
    type: :boolean,
    aliases: :m,
    desc: 'Create with migrations run after database created.'
  )
  option(
    :database,
    type: :string,
    aliases: :d,
    desc: 'Override the name of the database in the config.'
  )
  option(
    :type,
    type: :string,
    aliases: :t,
    desc: 'Choose database type. Choices are sqlite|postrgesql. \
    Defaults to sqlite.'
  )
  def create_db
    proxy.create_database(options)
    return unless options[:migrate]

    proxy.run_migrations
  end

  desc 'check_db', 'check state of database in config.'
  option(
    :migrated,
    type: :boolean,
    aliases: :m,
    desc: 'Check if migrated to latest schema.'
  )
  option(
    :database,
    type: :string,
    aliases: :d,
    desc: 'Override the name of the database to check from the config.'
  )
  def check
    puts('Database exists.') if proxy.check_db(options)
  end

  desc 'migrate_db', 'run migrations on database'
  option(
    :database,
    type: :string,
    aliases: :d,
    desc: 'Override the name of the database to migrate from the config.'
  )
  def migrate
    unless proxy.check_db(options)
      puts 'Cannot run migrations on a non-existent database.'
      puts "Run `create_db #{db_name_from_options}` first or \
            `create_db #{db_name_from_options} -m` to create with migrations."
    end
    proxy.run_migrations
  end

  desc 'interact', 'run the interactive program'
  def interact
    Interactive.new(proxy).run!
  end

  private

  def db_name_from_options
    @db_name_from_options ||= begin
      options[:database] || DB_CONFIG['fanalyzer']['database']
    end
  end

  def proxy
    @proxy ||= DatabaseProxy.new(
      db_name_from_options,
      options.fetch(:type, 'sqlite')
    )
  end
end
