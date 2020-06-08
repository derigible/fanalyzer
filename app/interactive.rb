# frozen_string_literal: true

require 'tty-prompt'
require 'tty-table'
require_relative 'uploaders/financial/csv'

class Interactive
  attr_reader :prompt, :db_proxy, :statements
  def initialize(database_proxy)
    @db_proxy = database_proxy
    @prompt = TTY::Prompt.new
    @statements = []
  end

  def run!
    result = prompt.select('What would you like to do?') do |menu|
      menu.enum '.'

      menu.choice name: 'Query Database', value: 1
      menu.choice name: 'Upload CSV to Database', value: 2
    end
    send("run_#{result}".to_s)
  end

  private

  def run_1
    result = prompt.select(
      'Select query option.',
      %i[custom],
      enum: '.'
    )
    send(result)
    puts result
    puts db_proxy.conn.from(result.to_s).all.count
  end

  def run_2
    Uploaders::Financial::Csv.new(db_proxy, prompt).run!
  end

  def custom
    sql = nil
    unless statements.empty?
      statement = prompt.select('Previous statements:') do |menu|
        menu.choice 'Create new statement', value: -1
        count = 0
        statements.each do |s|
          menu.choice s, value: count
          count += 1
        end
      end
      sql = statements[statement[:value]] if statement[:value] > -1
    end
    if sql.nil?
      sql = prompt.ask('Enter sql:')
    end
    results = db_proxy.conn[sql]
    table = TTY::Table.new(results.first.keys, results.map(&:values))
    puts table.render(:ascii)
    statements << sql unless statements.include? sql
    custom
  end
end
