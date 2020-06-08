# frozen_string_literal: true

require 'bundler/setup'

Bundler.require(:default)

require_relative 'app/fanalyze'

def run!
  Fanalyze.start(ARGV)
rescue TTY::Reader::InputInterrupt
  puts
  puts 'Exit program requested. Goodbye!'
  exit
end

run!
