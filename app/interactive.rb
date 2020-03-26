# frozen_string_literal: true

require 'tty-prompt'

class Interactive
  attr_reader :prompt, :db_proxy
  def initialize(database_proxy)
    @db_proxy = database_proxy
    @prompt = TTY::Prompt.new
  end

  def run!
    result = prompt.select('What would you like to do?') do |menu|
      menu.enum '.'

      menu.choice name: 'Query a Database', value: 1
      menu.choice name: 'Upload to a Database', value: 2
    end
    send("run_#{result}".to_s)
  end

  private

  def run_1
    choices = %w[Categories Sources Servicers Transactions]
    result = prompt.select('Select query option.', choices, enum: '.')
    puts result
    puts db_proxy.conn.from(result.to_s).all.count
  end

  def run_2
    puts 'path not implemented yet'
  end
end
