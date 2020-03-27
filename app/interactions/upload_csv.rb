# frozen_string_literal: true

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
      puts select_headers.run!
      puts data
    end

    private

    def select_headers
      @select_headers ||= Interactions::SelectHeaders.new(db_proxy, prompt)
    end

    def data
      prompt.ask('Enter the absolute path to the csv.') { |q| q.required true }
    end
  end
end
