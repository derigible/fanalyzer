# frozen_string_literal: true

require 'tty-prompt'

module Interactions
  class SelectHeaders
    CHOICES = %w[date description amount type servicer category].freeze

    attr_reader :prompt, :db_proxy

    def initialize(database_proxy, tty_prompt)
      @db_proxy = database_proxy
      @prompt = tty_prompt
    end

    def run!
      headers
    end

    # returns a hash of header values that map to the database columns
    # ie: <user_input_description>: "description" is how the key-value
    # mapping for the description column looks
    def headers
      @headers ||= begin
        normalize(display_saved_headings.values) || gather_headings
      end.invert
    end

    private

    def header_mapping
      @header_mapping ||= db_proxy.model(:header_mapping)
    end

    def normalize(hsh)
      hsh.delete(:name)
      hsh.delete(:id)
      hsh
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
      use == 'None' ? nil : headings.find { |h| h.name == use }
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
