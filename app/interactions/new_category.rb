# frozen_string_literal: true

module Interactions
  class NewCategory
    attr_reader :prompt, :category_model, :category

    def initialize(category, category_model, tty_prompt)
      @category = category
      @category_model = category_model
      @prompt = tty_prompt
    end

    def run!
      choice = prompt.select(
        "New category #{s.name}. What would you like to do?"
      ) do |menu|
        menu.choice 'Save', :save
        menu.choice 'Map to a different category permanently', :map_once
        menu.choice 'Map to a different category on this upload', :map_perm
        menu.choice(
          'Rename category (future categories will map to this name as well)',
          :rename
        )
      end

      send(choice)
    end

    private

    def save
      s = category_model.create name: category.name
      category.id = s.id
    end

    def remove
      category.id = 'remove'
    end

    def map_once
      use = find_category
      return run! if use == :none

      category.id = use.id
      category.name = use.name
    end

    def map_perm
      use = find_category
      return run! if use == :none

      category_model.create(
        name: category.name, category_id: use.id
      )
      category.id = use.id
      category.name = use.name
    end

    def rename
      new_name = prompt.ask?(
        'What should the new name be? (leave blank to select new choice)'
      )
      return run! if new_name == ''

      unless category_model[name: new_name].nil?
        puts("Category #{new_name} already exists.")
        return rename
      end

      create_and_map new_name
    end

    def find_category
      # exclude here creates a "category_id IS NOT NULL" clause
      categories = category_model.exclude(category_id: nil)
      prompt.select('Select category to map to') do |menu|
        categories.each do |s|
          menu.choice s.name, s.id
        end
        menu.choice 'None', :none
      end
    end

    def create_and_map(new_name)
      new_category = category_model.create name: new_name
      category_model.create name: category.name, category_id: new_category.id
      category.id = new_category.id
      category.name = new_name
    end
  end
end
