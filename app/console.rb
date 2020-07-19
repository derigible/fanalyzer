#!/usr/bin/env ruby
# frozen_string_literal: true

require 'irb'
require 'irb/completion'

class Console
  def run!
    ARGV.clear
    IRB.start
  end
end
