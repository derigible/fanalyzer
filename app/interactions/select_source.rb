# frozen_string_literal: true

module Interactions
  class SelectSource
    attr_reader :prompt, :sources

    def initialize(tty_prompt, sources)
      @prompt = tty_prompt
      @sources = sources
    end

    def run!
      display_saved_sources || define_new_source
    end

    private

    def display_saved_sources
      availabe_sources = sources.all
      puts('No sources found.') && return if availabe_sources.empty?

      use = prompt.select(
        'Select source of file.',
        availabe_sources.map(&:name) + ['None'],
        enum: '.'
      )
      use == 'None' ? nil : availabe_sources.find { |s| s.name == use }
    end

    def define_new_source
      name = prompt.ask('Name of new source (leave blank to start over):')

      return run! if name == ''

      sources.create(name: name)
    end
  end
end
