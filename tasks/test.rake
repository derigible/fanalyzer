# frozen_string_literal: true

require 'rake/testtask'
require 'csv'
require 'active_support/core_ext/numeric/time'

require_relative '../app/interactions/select_headers'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'app'
  t.test_files = FileList['test/**/test_*.rb']
end

task default: :test

namespace :test do
  desc 'Setup fixture data'
  task :fixture do
    CSV.open('test/fixtures/start.csv', 'wb', force_quotes: true) do |csv|
      csv << Interactions::SelectHeaders::CHOICES
      100.times do |i|
        csv << [
          i.days.ago.strftime('%m/%d/%Y'),
          "Description #{i}",
          rand(0.0..100.00).ceil(2),
          %w[debit credit].sample,
          '',
          ['CREDIT CARD 1', 'CHECKING', 'SAVINGS'].sample,
          ['TEST 1', 'TEST 2'].sample
        ]
      end
    end
  end
end
