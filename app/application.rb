# frozen_string_literal: true

require 'tty-prompt'
require 'tty-table'
require_relative 'uploaders/financial/csv'
require_relative 'editors/transaction'
require_relative 'queries/custom'
require_relative 'queries/by_category'
require_relative 'queries/by_servicer'
require_relative 'queries/by_date'
require_relative 'comparisons/by_category'
require_relative 'comparisons/by_servicer'
require_relative 'comparisons/by_income'
require_relative 'comparisons/by_expenses'

class Application
  attr_reader :prompt, :db_proxy
  def initialize(database_proxy)
    @db_proxy = database_proxy
    @prompt = TTY::Prompt.new
  end

  def run!
    result = prompt.select('What would you like to do?') do |menu|
      menu.enum '.'

      menu.choice name: 'Query', value: :query
      menu.choice name: 'Compare', value: :compare
      menu.choice name: 'Upload Data', value: :upload_data
      menu.choice name: 'Update/Browse Data', value: :update_data
    end
    send(result)
  end

  private

  def query
    result = prompt.select('Select query option.', enum: '.') do |menu|
      menu.choice name: 'Tranactions by Category', value: :by_category
      menu.choice name: 'Tranactions by Servicer', value: :by_servicer
      menu.choice name: 'Tranactions by Date', value: :by_date
      menu.choice name: 'Custom', value: :custom
    end
    "Queries::#{result.to_s.camelize}".constantize.new(db_proxy, prompt).run!
  end

  def compare
    result = prompt.select('Select comparison option.', enum: '.') do |menu|
      menu.choice 'Transactions by Category', :by_category
      menu.choice 'Transactions by Servicer', :by_servicer
      menu.choice 'Income', :by_income
      menu.choice 'Expenses', :by_expenses
    end
    "Comparisons::#{result.to_s.camelize}".constantize.new(
      db_proxy, prompt
    ).run!
  end

  def upload_data
    result = prompt.select('Select type to upload.') do |menu|
      menu.enum '.'

      menu.choice name: 'Financial CSV', value: :financial_csv
    end

    type = result.to_s.split('_').map(&:camelize).join('::')

    "Uploaders::#{type}".constantize.new(db_proxy, prompt).run!
  end

  def update_data
    result = prompt.select('Select type to edit.') do |menu|
      menu.enum '.'

      menu.choice name: 'Transaction', value: :transaction
    end

    "Editors::#{result.to_s.camelize}".constantize.new(db_proxy, prompt).run!
  end
end
