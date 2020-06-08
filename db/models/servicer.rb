# frozen_string_literal: true

module Models
  class Servicer < Sequel::Model
    def mapped_id
      return id if servicer_id.nil?

      parent = self.class[servicer_id]
      parent.mapped_id
    end
  end
end
