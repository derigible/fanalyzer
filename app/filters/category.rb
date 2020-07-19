# frozen_string_literal: true

module Filters
  module Category
    private

    def category_filters(models)
      if prompt.yes?('Filter by category?')
        filter_by_category!(models)
      else
        models
      end
    end

    def filter_by_category!(models)
      use = prompt.select(
        'Choose category filtering strategy to apply:',
        enum: '.',
        per_page: 7
      ) do |menu|
        menu.choice 'Exclude transactions with categories', :exclude_categories
        menu.choice 'Include transactions with categories', :include_categories
        menu.choice 'Cancel', :cancel
      end
      return models if use == :cancel

      send(use, models)
    end

    def exclude_categories(models)
      excluding = prompt.multi_select(
        'Choose categories to exclude (press enter when all selected)'
      ) do |menu|
        category_names.each do |l|
          menu.choice l[:name], l[:id]
        end
      end
      models.exclude(category_id: excluding)
    end

    def include_categories(models)
      including = prompt.multi_select(
        'Choose categories to include (press enter when all selected)'
      ) do |menu|
        category_names.each do |l|
          menu.choice l[:name], l[:id]
        end
      end
      models.where(category_id: including)
    end

    def category_model
      @category_model ||= proxy.model(:category)
    end

    def category_names
      @category_names ||= category_model.map do |l|
        { name: l.name, id: l.id }
      end
    end
  end
end
