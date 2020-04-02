# frozen_string_literal: true

require 'csv'
require 'tty-prompt'
require_relative 'select_headers'

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
      load_csv select_file(paths), headers
    end

    private

    def file_path_history
      @file_path_history ||= begin
        tmp_file = File.join(File.dirname(__FILE__), '../../tmp/csv-files')
        File.new tmp_file, 'a+'
      end
    end

    def load_csv(file, _headers)
      CSV.open(file, headers: true).each do |r|
        debugger
        r
      end
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
  end
end
