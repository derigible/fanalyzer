# frozen_string_literal: true

class Servicer < Sequel::Model
  one_to_many :transactions

  def mapped_id
    return id if servicer_id.nil?

    parent = self.class[servicer_id]
    parent.mapped_id
  end

  def to_struct
    OpenStruct.new(
      id: id,
      name: name
    )
  end
end
