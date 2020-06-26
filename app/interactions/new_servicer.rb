# frozen_string_literal: true

module Interactions
  class NewServicer
    attr_reader :prompt, :servicer_model, :servicer, :upload_id

    def initialize(servicer, servicer_model, tty_prompt, upload_id)
      @servicer = servicer
      @servicer_model = servicer_model
      @prompt = tty_prompt
      @upload_id = upload_id
    end

    def run!
      choice = prompt.select(
        "New servicer #{servicer.name}. What would you like to do?",
        enum: '.'
      ) do |menu|
        menu.choice 'Save', :save
        menu.choice(
          'Remove (will remove all transactions on this upload)', :remove
        )
        menu.choice 'Map to a different servicer permanently', :map_perm
        menu.choice 'Map to a different servicer on this upload', :map_once
        menu.choice(
          'Rename servicer (future servicers will map to this name)', :rename
        )
      end

      send(choice, method(:run!))
    end

    def transaction_edit!
      choice = prompt.select(
        "Changing servicer #{servicer.name} on transaction. " \
        'What would you like to do?',
        enum: '.'
      ) do |menu|
        menu.choice 'Keep', :keep
        menu.choice 'Edit a different transaction field', :edit_different
        menu.choice 'Map to a different servicer on this upload', :map_once
        menu.choice(
          'Rename servicer (future servicers will map to this name)', :rename
        )
      end

      return choice if %i[keep edit_different].include? choice

      send(choice, method(:transaction_edit!))
    end

    private

    def save(_return_func)
      s = servicer_model.create name: servicer.name, upload_id: upload_id
      servicer.id = s.id
    end

    def remove(_return_func)
      servicer.id = 'remove'
    end

    def map_once(return_func)
      use = find_servicer
      return return_func.call if use == :none

      servicer.id = use.id
      servicer.name = use.name
    end

    def map_perm(return_func)
      use = find_servicer
      return return_func.call if use == :none

      servicer_model.create(
        name: servicer.name, servicer_id: use.id, upload_id: upload_id
      )
      servicer.id = use.id
      servicer.name = use.name
    end

    def rename(return_func)
      new_name = prompt.ask(
        'What should the new name be? (leave blank to select new choice)'
      )
      return return_func.call if new_name == ''

      unless servicer_model[name: new_name].nil?
        puts("Servicer #{new_name} already exists.")
        return rename
      end

      create_and_map new_name
    end

    def find_servicer
      servicers = servicer_model
      prompt.select('Select servicer to map to') do |menu|
        servicers.each do |s|
          menu.choice s.name, s
        end
        menu.choice 'None', :none
      end
    end

    def create_and_map(new_name)
      new_servicer = servicer_model.create name: new_name, upload_id: upload_id
      servicer_model.create(
        name: servicer.name, servicer_id: new_servicer.id, upload_id: upload_id
      )
      servicer.id = new_servicer.id
      servicer.name = new_name
      new_servicer
    end
  end
end
