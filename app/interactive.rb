# frozen_string_literal: true

require 'tty-prompt'
require 'tty-table'
require_relative 'uploaders/financial/csv'
require_relative 'editors/transaction'
require_relative 'queries/custom'
require_relative 'queries/by_category'
require_relative 'queries/by_servicer'
require_relative 'queries/by_date'

class Interactive
  attr_reader :prompt, :db_proxy
  def initialize(database_proxy)
    @db_proxy = database_proxy
    @prompt = TTY::Prompt.new
  end

  def run!
    result = prompt.select('What would you like to do?') do |menu|
      menu.enum '.'

      menu.choice name: 'Query', value: 1
      menu.choice name: 'Upload Data', value: 2
      menu.choice name: 'Update Data', value: 3
    end
    send("run_#{result}".to_s)
  end

  private

  def run_1
    result = prompt.select('Select query option.', enum: '.') do |menu|
      menu.choice name: 'Custom', value: :custom
      menu.choice name: 'Tranactions by Category', value: :by_category
      menu.choice name: 'Tranactions by Servicer', value: :by_servicer
      menu.choice name: 'Tranactions by Date', value: :by_date
    end
    "Queries::#{result.to_s.camelize}".constantize.new(db_proxy, prompt).run!
  end

  def run_2
    result = prompt.select('Select type to upload.') do |menu|
      menu.enum '.'

      menu.choice name: 'Financial CSV', value: :financial_csv
    end

    type = result.to_s.split('_').map(&:camelize).join('::')

    "Uploaders::#{type}".constantize.new(db_proxy, prompt).run!
  end

  def run_3
    result = prompt.select('Select type to edit.') do |menu|
      menu.enum '.'

      menu.choice name: 'Transaction', value: :transaction
    end

    "Editors::#{result.to_s.camelize}".constantize.new(db_proxy, prompt).run!
  end
end
