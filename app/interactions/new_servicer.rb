# frozen_string_literal: true

module Interactions
  class NewServicer
    attr_reader :prompt, :servicer_model, :servicer

    def initialize(servicer, servicer_model, tty_prompt)
      @servicer = servicer
      @servicer_model = servicer_model
      @prompt = tty_prompt
    end

    def run!
      choice = prompt.select(
        "New servicer #{servicer.name}. What would you like to do?"
      ) do |menu|
        menu.choice 'Save', :save
        menu.choice(
          'Remove (will remove all transactions on this upload)', :remove
        )
        menu.choice 'Map to a different servicer permanently', :map_once
        menu.choice 'Map to a different servicer on this upload', :map_perm
        menu.choice(
          'Rename servicer (future servicers will map to this name)', :rename
        )
      end

      send(choice)
    end

    private

    def save
      s = servicer_model.create name: servicer.name
      servicer.id = s.id
    end

    def remove
      servicer.id = 'remove'
    end

    def map_once
      use = find_servicer
      return run! if use == :none

      servicer.id = use.id
      servicer.name = use.name
    end

    def map_perm
      use = find_servicer
      return run! if use == :none

      servicer_model.create(
        name: servicer.name, servicer_id: use.id
      )
      servicer.id = use.id
      servicer.name = use.name
    end

    def rename
      new_name = prompt.ask?(
        'What should the new name be? (leave blank to select new choice)'
      )
      return run! if new_name == ''

      unless servicer_model[name: new_name].nil?
        puts("Servicer #{new_name} already exists.")
        return rename
      end

      create_and_map new_name
    end

    def find_servicer
      # exclude here creates a "servicer_id IS NOT NULL" clause
      servicers = servicer_model.exclude(servicer_id: nil)
      prompt.select('Select servicer to map to') do |menu|
        servicers.each do |s|
          menu.choice s.name, s.id
        end
        menu.choice 'None', :none
      end
    end

    def create_and_map(new_name)
      new_servicer = servicer_model.create name: new_name
      servicer_model.create name: servicer.name, servicer_id: new_servicer.id
      servicer.id = new_servicer.id
      servicer.name = new_name
    end
  end
end
