# frozen_string_literal: true

module Filters
  module Servicer
    private

    def servicer_filters(models)
      if prompt.yes?('Filter by servicer?')
        filter_by_servicer!(models)
      else
        models
      end
    end

    def filter_by_servicer!(models)
      use = prompt.select(
        'Choose servicer filtering strategy to apply:',
        enum: '.',
        per_page: 7
      ) do |menu|
        menu.choice 'Exclude transactions with servicers', :exclude_servicers
        menu.choice 'Include transactions with servicers', :include_servicers
        menu.choice 'Cancel', :cancel
      end
      return models if use == :cancel

      send(use, models)
    end

    def exclude_servicers(models)
      excluding = prompt.multi_select(
        'Choose servicers to exclude (press enter when all selected)'
      ) do |menu|
        servicer_names.each do |l|
          menu.choice l[:name], l[:id]
        end
      end
      models.exclude(servicer_id: excluding)
    end

    def include_servicers(models)
      including = prompt.multi_select(
        'Choose servicers to include (press enter when all selected)'
      ) do |menu|
        servicer_names.each do |l|
          menu.choice l[:name], l[:id]
        end
      end
      models.where(servicer_id: including)
    end

    def servicer_model
      @servicer_model ||= proxy.model(:servicer)
    end

    def servicer_names
      @servicer_names ||= servicer_model.map do |l|
        { name: l.name, id: l.id }
      end
    end
  end
end
