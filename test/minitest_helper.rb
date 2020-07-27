# frozen_string_literal: true

require 'bundler/setup'

Bundler.require(:default)

require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/hooks/test'

require_relative '../db/database_proxy'
require_relative '../app/uploaders/financial/csv'
require_relative '../app/interactions/select_headers'

gem_dir = Gem::Specification.find_by_name('tty-prompt').gem_dir
require "#{gem_dir}/lib/tty/prompt/test"

class FanalyzeTest < Minitest::Test
  include Minitest::Hooks

  def before_all
    super
    @db_proxy = DatabaseProxy.new(
      'test-fanalyzer',
      'sqlite'
    )
    return if @db_proxy.check_db

    @db_proxy.create_database(force: true)
    @db_proxy.run_migrations
    add_fixture_data
    puts 'Database is now setup.'
  end

  def around
    @db_proxy.conn.transaction(
      rollback: :always, savepoint: true, auto_savepoint: true
    ) do
      super
    end
  end

  private

  def add_fixture_data
    upload_test_prompt = TTY::Prompt::Test.new
    Uploaders::Financial::Csv.new(
      @db_proxy,
      upload_test_prompt,
      quiet: true,
      csv_file: csv_file_path,
      source: source,
      headers: headers,
      date_format: '%m/%d/%Y'
    )
  end

  def csv_file_path
    File.join(
      File.dirname(__FILE__), 'fixtures/start.csv'
    )
  end

  def source
    @db_proxy.model(:source).create(name: 'Test Source')
  end

  def headers
    Interactions::SelectHeaders::CHOICES.each_with_object({}) do |v, memo|
      memo[v.to_sym] = v
    end
  end
end
