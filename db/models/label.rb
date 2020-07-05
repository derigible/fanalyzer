# frozen_string_literal: true

module Models
  class Label < Sequel::Model
    many_to_many :transactions

    def to_struct
      OpenStruct.new(
        id: id,
        name: name
      )
    end
  end
end
