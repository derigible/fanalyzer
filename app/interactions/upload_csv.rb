# frozen_string_literal: true

require 'tty-prompt'

module Interactions
  class UploadCsv
    CHOICES = %w[date description amount type servicer category].freeze

    attr_reader :prompt, :db_proxy

    def initialize(database_proxy, tty_prompt)
      @db_proxy = database_proxy
      @prompt = tty_prompt
    end

    def run!
      headers = display_saved_headings
      headers ||= gather_headings
      headers
    end

    private

    def header_mapping
      @header_mapping ||= db_proxy.model(:header_mapping)
    end

    def display_saved_headings
      headings = header_mapping.all
      puts('No header mappings found.') && return if headings.empty?
      return use_single(headings) if headings.size == 1

      use_multiple(headings)
    end

    def use_single(headings)
      prompt.yes?("Use #{headings.first.name}?") ? headings.first : nil
    end

    def use_multiple(headings)
      use = prompt.select(
        'Select mapping to use.',
        headings.map(&:name) + ['None'],
        enum: '.'
      )
      use == 'None' ? nil : headings.where(name: use)
    end

    def gather_headings
      results = prompt_for_headings
      return gather_headings unless prompt.yes?('Keep?')

      name = prompt.ask(
        'Name of header mapping (leave blank to not save):'
      )
      mapping = create_mapping(results)
      header_mapping.create(mapping.merge!(name: name)) if name
      mapping
    end

    def prompt_for_headings
      results = CHOICES.map do |c|
        prompt.ask(
          "What is the heading for #{c.capitalize} (Leave empty if same)?"
        ) || c
      end
      puts 'This is what you have selected:'
      CHOICES.each_with_index { |c, i| puts "#{c} => #{results[i]}" }
      results
    end

    def create_mapping(results)
      CHOICES.zip(results).to_h
    end
  end
end
