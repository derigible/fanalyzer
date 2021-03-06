# frozen_string_literal: true

module Filters
  module Label
    private

    def label_filters(models)
      if prompt.yes?('Filter by label?')
        filter_by_label!(models)
      else
        models
      end
    end

    def filter_by_label!(models, additional = false)
      use = prompt.select(
        'Choose label filtering strategy to apply:',
        enum: '.',
        per_page: 7
      ) do |menu|
        if additional
          menu.choice(
            'Exclude transactions without label', :exclude_without_labels
          )
          menu.choice 'Continue (no additional filters)', :cancel
        else
          menu.choice 'Exclude transactions with labels', :exclude_labels
          menu.choice 'Include transactions with labels', :include_labels
          menu.choice 'Cancel', :cancel
        end
      end
      return models if use == :cancel

      send(use, models)
    end

    def exclude_labels(models)
      excluding = prompt.multi_select(
        'Choose labels to exclude (press enter when all selected)'
      ) do |menu|
        label_names.each do |l|
          menu.choice l[:name], l[:id]
        end
      end
      filter_by_label!(
        models.exclude(labels: label_model.where(id: excluding)), true
      )
    end

    def exclude_without_labels(models)
      excluding = prompt.multi_select(
        'Choose labels to exclude if label missing ' \
        '(press enter when all selected)'
      ) do |menu|
        label_names.each do |l|
          menu.choice l[:name], l[:id]
        end
      end
      filter_by_label!(
        models.where(labels: label_model.where(id: excluding)), true
      )
    end

    def include_labels(models)
      including = prompt.multi_select(
        'Choose labels to include (press enter when all selected)'
      ) do |menu|
        label_names.each do |l|
          menu.choice l[:name], l[:id]
        end
      end
      filter_by_label!(
        models.where(labels: label_model.where(id: including)), true
      )
    end

    def label_model
      @label_model ||= proxy.model(:label)
    end

    def label_names
      @label_names ||= label_model.map do |l|
        { name: l.name, id: l.id }
      end
    end
  end
end
