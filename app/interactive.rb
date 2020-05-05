# frozen_string_literal: true

require 'tty-prompt'
require_relative 'uploaders/financial/csv'

class Interactive
  attr_reader :prompt, :db_proxy
  def initialize(database_proxy)
    @db_proxy = database_proxy
    @prompt = TTY::Prompt.new
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
      %w[Categories Sources Servicers Transactions],
      enum: '.'
    )
    puts result
    puts db_proxy.conn.from(result.to_s).all.count
  end

  def run_2
    Uploaders::Financial::Csv.new(db_proxy, prompt).run!
  end
end
