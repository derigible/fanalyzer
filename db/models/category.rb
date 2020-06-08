# frozen_string_literal: true

module Models
  class Category < Sequel::Model
    def mapped_id
      return id if category_id.nil?

      parent = self.class[category_id]
      parent.mapped_id
    end
  end
end
