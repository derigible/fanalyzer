# frozen_string_literal: true

require 'bundler/setup'

Bundler.require(:default)

require_relative 'app/fanalyze'

Fanalyze.start(ARGV)
