# frozen_string_literal: true

class Category < Sequel::Model
  one_to_many :transactions

  def mapped_id
    return id if category_id.nil?

    parent = self.class[category_id]
    parent.mapped_id
  end

  def to_struct
    OpenStruct.new(
      id: id,
      name: name
    )
  end
end
