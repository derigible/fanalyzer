# frozen_string_literal: true

module Models
  class Transaction < Sequel::Model
    many_to_one :servicer
    many_to_one :category

    def to_struct
      OpenStruct.new(
        id: id,
        date: date,
        description: description,
        amount: amount,
        is_debit: is_debit,
        servicer: servicer.to_struct,
        category: category.to_struct
      )
    end
  end
end
