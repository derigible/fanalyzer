# frozen_string_literal: true

require 'yaml'
require 'byebug'

REPO_CONFIG_PATH = File.join(File.dirname(__FILE__), '..', 'repo')
REPO_CONFIG = YAML.load_file(
  File.join(REPO_CONFIG_PATH, 'config.yml')
)

# Main entry to analyzer
class Fanalyze < Thor
  desc 'create_repo REPO', 'create a new transactions repository of name REPO'
  option(
    :force,
    type: :boolean,
    aliases: :f,
    desc: 'Force the creation. WARNING: will destroy previous repo!'
  )
  def create_repo(repo)
    if check_repo(repo)
      unless options[:force]
        puts "Cannot create #{repo} as it already exists!"
        puts 'If you want to drop the repo and recreate, use the -f flag'
        return
      end
    end
    db.execute "DROP DATABASE IF EXISTS #{repo}" if options[:force]
    db.execute "CREATE DATABASE #{repo}"
  end

  desc 'check REPO', 'check REPO state.'
  option(
    :migrated,
    type: :boolean,
    aliases: :m,
    desc: 'Check if migrated to latest schema.'
  )
  def check(repo)
    check_repo(repo, options)
  end

  private

  def db
    @db ||= Sequel.postgres(REPO_CONFIG.merge('database' => 'postgres'))
  end

  def check_repo(repo, opts)
    output = db[
      'SELECT 1 where EXISTS(
        select datname from pg_catalog.pg_database
        where lower(datname) = lower(?)
      );',
      repo
    ]
    if output.first.nil?
      puts 'Repo does not exist'
      return false
    end
    result = true
    if opts[:migrated]
      Sequel.extension :migration
      result = Sequel::Migrator.is_current?(
        db, File.join(REPO_CONFIG_PATH, 'migrations/')
      )
      puts 'Repo not migrated to latest' unless result
    end

    result
  end
end
