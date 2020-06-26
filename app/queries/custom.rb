# frozen_string_literal: true

module Queries
  class Custom
    attr_accessor :proxy, :prompt, :statements

    def initialize(db_proxy, tty_prompt)
      @proxy = db_proxy
      @prompt = tty_prompt
      @statements = []
    end

    def run!
      sql = nil
      unless statements.empty?
        statement = prompt.select(
          'Previous statements:',
          enum: '.'
        ) do |menu|
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
      results = proxy.conn[sql]
      table = TTY::Table.new(results.first.keys, results.map(&:values))
      puts table.render(:ascii)
      statements << sql unless statements.include? sql
      run!
    end
  end
end
