# frozen_string_literal: true

module Interactions
  class SelectDateFormat
    attr_reader :prompt, :header_mapping

    def initialize(header_mapping, tty_prompt)
      @header_mapping = header_mapping
      @prompt = tty_prompt
    end

    def run!(id)
      fmt = use_stored(id)
      return fmt if fmt

      date_format(id)
    end

    private

    def use_stored(id)
      return if id.nil?

      header_mapping[id]&.date_format
    end

    def date_format(id)
      fmt = prompt.select('Select format date column is in.') do |menu|
        menu.enum '.'

        menu.choice 'Month/Day/Year (mm/dd/yyyy)', '%m/%d/%Y'
        menu.choice 'Day/Month/Year (dd/mm/yyyy)', '%d/%m/%Y'
        menu.choice 'Year-Month-Day (yyyy-mm-dd)', '%Y-%m-%d'
      end

      header_mapping[id]&.update(date_format: fmt) unless id.nil?
      fmt
    end
  end
end
