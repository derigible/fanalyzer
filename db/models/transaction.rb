# frozen_string_literal: true

require 'active_support/core_ext/string'

class Transaction < Sequel::Model
  many_to_one :servicer
  many_to_one :category
  many_to_many :labels

  def to_struct
    OpenStruct.new(
      id: id,
      date: date,
      description: description,
      amount: amount,
      is_debit: is_debit,
      notes: notes,
      category: category.to_struct,
      servicer: servicer.to_struct,
      labels: labels.map(&:to_struct)
    )
  end

  def to_table_row
    t = to_struct
    t.category = t.category.name
    t.servicer = t.servicer.name
    t.labels = t.labels.map(&:name).join(',')
    t.upload_id = upload_id
    t.is_debit = is_debit ? 'debit' : 'credit'
    t.to_h.values
  end

  def table_keys
    keys.map do |k|
      if k.end_with?('_id')
        k.to_s.split('_').first
      elsif k == :is_debit
        'type'
      else
        k
      end
    end.map(&:to_s).map(&:titleize)
  end
end
