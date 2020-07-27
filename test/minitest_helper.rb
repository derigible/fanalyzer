# frozen_string_literal: true

require 'bundler/setup'

Bundler.require(:default)

require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/hooks/test'

require_relative '../db/database_proxy'

class FanalyzeTest < Minitest::Test
  include Minitest::Hooks

  def before_all
    super
    @db_proxy = DatabaseProxy.new(
      'test-fanalyzer',
      'sqlite'
    )
    @db_proxy.create_database(force: true)
    @db_proxy.run_migrations
  end
end
