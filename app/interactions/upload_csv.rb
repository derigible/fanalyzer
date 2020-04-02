# frozen_string_literal: true

require 'csv'
require 'tty-prompt'
require_relative 'select_headers'
require_relative '../uploaders/transactions'

module Interactions
  class UploadCsv
    attr_reader :prompt, :db_proxy

    def initialize(database_proxy, tty_prompt)
      @db_proxy = database_proxy
      @prompt = tty_prompt
    end

    def run!
      headers = select_headers.run!
      paths = file_path_history.readlines(chomp: true)
      date_format = date_format
      load_csv select_file(paths), headers, date_format
    end

    private

    def file_path_history
      @file_path_history ||= begin
        tmp_file = File.join(File.dirname(__FILE__), '../../tmp/csv-files')
        File.new tmp_file, 'a+'
      end
    end

    def load_csv(file, headers, date_format)
      Uploaders::Transactions.new(db_proxy, file, headers, date_format).upload!
    end

    def select_headers
      @select_headers ||= Interactions::SelectHeaders.new(db_proxy, prompt)
    end

    def select_file(paths)
      use = prompt.select('Select path to csv.', paths + ['None'], enum: '.')
      use == 'None' ? file(paths.last) : use
    end

    def file(value = nil)
      file_path = prompt.ask(
        'Enter the absolute path to the csv.', value: value.nil? ? '' : value
      ) { |q| q.required true }
      if File.exist?(file_path)
        if File.file? file_path
          save_file_choice(file_path)
        else
          puts 'Directory given. Please provide a path to a file.'
          file(file_path)
        end
      else
        puts 'File path not valid, please enter a valid file path.'
        file(file_path)
      end
    end

    def save_file_choice(file_path)
      f = File.new(file_path)
      file_path_history.write(File.realpath(f))
      file_path_history.close
      f
    end

    def date_format
      prompt.select('Select format date column is in.') do |menu|
        menu.enum '.'

        menu.choice name: 'Month/Day/Year (mm/dd/yyyy)', value: '%m/%d/%Y'
        menu.choice name: 'Day/Month/Year (dd/mm/yyyy)', value: '%d/%m/%Y'
        menu.choice name: 'Year-Month-Day (yyyy-mm-dd)', value: '%Y-%m-%d'
      end
    end
  end
end
