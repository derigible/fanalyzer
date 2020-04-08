# frozen_string_literal: true

module Interactions
  class SelectDateFormat
    attr_reader :prompt, :db_proxy

    def initialize(database_proxy, tty_prompt)
      @db_proxy = database_proxy
      @prompt = tty_prompt
    end

    def run!(id)
      use_stored(id) && return
      date_format(id)
    end

    private

    def use_stored(id)
      return if id.nil?

      header_mapping[id]&.date_format
    end

    def header_mapping
      @header_mapping ||= db_proxy.model(:header_mapping)
    end

    def date_format(id)
      fmt = prompt.select('Select format date column is in.') do |menu|
        menu.enum '.'

        menu.choice name: 'Month/Day/Year (mm/dd/yyyy)', value: '%m/%d/%Y'
        menu.choice name: 'Day/Month/Year (dd/mm/yyyy)', value: '%d/%m/%Y'
        menu.choice name: 'Year-Month-Day (yyyy-mm-dd)', value: '%Y-%m-%d'
      end

      header_mapping[id]&.update date_format: fmt unless id.nil?
      fmt
    end
  end
end
