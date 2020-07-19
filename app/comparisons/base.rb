# frozen_string_literal: true

require_relative './concerns/date'
require_relative '../filters/label'
require_relative '../filters/category'
require 'active_support/core_ext/numeric/conversions'
require 'active_support/core_ext/array/access'

Comparison = Struct.new(:description, :transactions, :sum, :iteration)

module Comparisons
  class Base
    include Comparisons::Concerns::Date
    include Filters::Category
    include Filters::Label
    attr_accessor :proxy, :prompt

    def initialize(db_proxy, tty_prompt)
      @proxy = db_proxy
      @prompt = tty_prompt
    end

    def run!
      raise NotImplentedError
    end

    private

    def compare(models)
      compared = comparisons(filters(models)).to_a
      print_compared(compared)
      print_differences(compared)
    end

    def filters(models)
      models = category_filters(models)
      label_filters(models)
    end

    def comparisons(models)
      date_comparisons(models)
    end

    def print_compared(compared)
      return if compared.empty?

      puts
      puts 'Sum of Transactions for Each Date Range of Each Comparison:'
      puts
      headers = compared.map do |c|
        c.map(&:description)
      end.flatten
      values = compared.map do |c|
        c.map(&:sum)
      end.flatten
      print_table(headers, values)
    end

    def print_differences(compared)
      return if compared.empty?

      puts
      puts 'Difference for Each Comparison:'
      puts
      headers = compared.map do |c|
        "Comparison #{c.first.iteration} Difference"
      end
      values = compared.map do |c|
        c.first.sum - c.second.sum
      end
      print_table(headers, values)
    end

    def print_table(headers, values)
      table = TTY::Table.new(
        headers,
        [values]
      )
      puts table.render(
        :ascii, alignment: :center, multiline: true
      )
    end

    def make_comparison(iteration, range, models)
      result = models.where(date: Range.new(*range))
      Comparison.new(
        "Comparison #{iteration + 1}\n" \
        "#{fmt_date(range.second)}\nto\n" \
        "#{fmt_date(range.first)}",
        result,
        sum(result),
        iteration + 1
      )
    end

    def fmt_date(date)
      date.strftime('%m/%d/%Y')
    end

    def sum(result)
      result.to_a.sum { |t| t.is_debit ? t.amount : -t.amount }
    end

    def transaction_model
      @transaction_model ||= proxy.model(:transaction)
    end
  end
end
