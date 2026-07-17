# frozen_string_literal: true
require "csv"
require_relative "../account"

class AccountLoader
  def self.load(csv_path)
    arr_of_rows = CSV.read(csv_path)
    # | acc_number, acc_balance | will destructure the row to make it more readable
    arr_of_rows.map { |acc_number, acc_balance| Account.new(number: acc_number, balance: BigDecimal(acc_balance)) }
  end
end