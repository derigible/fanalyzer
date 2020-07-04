# frozen_string_literal: true

module Interactions
  class NewCategory
    attr_reader :prompt, :category_model, :category, :upload_id

    def initialize(category, category_model, tty_prompt, upload_id)
      @category = category
      @category_model = category_model
      @prompt = tty_prompt
      @upload_id = upload_id
    end

    def run!
      return if category.name.nil?

      choice = prompt.select(
        "New category #{category.name}. What would you like to do?",
        enum: '.'
      ) do |menu|
        menu.choice 'Save', :save
        menu.choice 'Map to a different category permanently', :map_perm
        menu.choice 'Map to a different category on this upload', :map_once
        menu.choice(
          'Rename category (future categories will map to this name as well)',
          :rename
        )
      end

      send(choice, method(:run!))
    end

    def transaction_edit!
      choice = prompt.select(
        "Changing category #{category.name} on transaction. What would you " \
        'like to do?'
      ) do |menu|
        menu.choice 'Keep', :keep
        menu.choice 'Edit a different transaction field', :edit_different
        menu.choice 'Map to a different category on this upload', :map_once
        menu.choice(
          'Rename category (future categories will map to this name)', :rename
        )
      end

      return choice if %i[keep edit_different].include? choice

      send(choice, method(:transaction_edit!))
    end

    private

    def save(_return_func)
      s = category_model.create name: category.name, upload_id: upload_id
      category.id = s.id
    end

    def remove(_return_func)
      category.id = 'remove'
    end

    def map_once(return_func)
      use = find_category
      return return_func.call if use == :none

      category.id = use.id
      category.name = use.name
    end

    def map_perm(return_func)
      use = find_category
      return return_func.call if use == :none

      category_model.create(
        name: category.name, category_id: use.id, upload_id: upload_id
      )
      category.id = use.id
      category.name = use.name
    end

    def rename(return_func)
      new_name = prompt.ask(
        'What should the new name be? (leave blank to select new choice)'
      )
      return return_func.call if new_name.empty?

      unless category_model[name: new_name].nil?
        puts("Category #{new_name} already exists.")
        return rename
      end

      create_and_map new_name
    end

    def find_category
      categories = category_model
      prompt.select(
        'Select category to map to (type to search)', filter: true
      ) do |menu|
        categories.each do |c|
          menu.choice c.name, c
        end
        menu.choice 'None', :none
      end
    end

    def create_and_map(new_name)
      new_category = category_model.create name: new_name, upload_id: upload_id
      category_model.create(
        name: category.name, category_id: new_category.id, upload_id: upload_id
      )
      category.id = new_category.id
      category.name = new_name
      new_category
    end
  end
end
