# frozen_string_literal: true

require "csv"
require "bigdecimal"
require_relative "../account"

class AccountLoader
  def self.load(csv_path)
    CSV.read(csv_path).filter_map { |row| build_account(row) }
  end

  # A malformed row (wrong column count, non-numeric balance) shouldn't crash
  # loading every other account in the file - skip it and warn instead.
  def self.build_account(row)
    acc_number, acc_balance = row
    Account.new(number: acc_number, balance: BigDecimal(acc_balance))
  rescue ArgumentError, TypeError
    warn "AccountLoader: skipping malformed row #{row.inspect}"
    nil
  end
  private_class_method :build_account
end
