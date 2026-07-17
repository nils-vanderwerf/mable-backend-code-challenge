# frozen_string_literal: true
require "csv"
require "bigdecimal"
require_relative "../transfer"

class TransferLoader
  def self.load(csv_path)
    arr_of_rows = CSV.read(csv_path)
    # | from_acc, to_acc, amount | will destructure the row to make it more readable
    arr_of_rows.map { |from_acc, to_acc, amount| Transfer.new(from: from_acc, to: to_acc, amount: BigDecimal(amount)) }
  end
end