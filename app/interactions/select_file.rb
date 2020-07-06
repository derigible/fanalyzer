# frozen_string_literal: true

module Interactions
  class SelectFile
    attr_reader :prompt, :file_type

    def initialize(tty_prompt, file_type)
      @prompt = tty_prompt
      @file_type = file_type
    end

    def run!
      paths = file_path_history.readlines(chomp: true)
      select_file(paths)
    end

    private

    def file_path_history
      @file_path_history ||= begin
        tmp_file = File.join(
          File.dirname(__FILE__), "../../tmp/#{file_type}-files"
        )
        File.new tmp_file, 'a+'
      end
    end

    def select_file(paths)
      use = prompt.select(
        "Select path to #{file_type}.",
        paths + ['None'],
        enum: '.'
      )
      use == 'None' ? file(paths.last) : use
    end

    def file(value = nil)
      file_path = prompt.ask(
        "Enter the absolute path to the #{file_type}.",
        value.nil? ? '' : value
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
