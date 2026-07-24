# frozen_string_literal: true

require "csv"
require "bigdecimal"
require_relative "../account"

class AccountLoader
  # private_class_method here, not the instance + new(...).call pattern BatchRunner uses -
  # these are pure functions of their arguments, no state to share between calls, so
  # there's no reason to pay for an instance.
  def self.load(csv_path)
    rows = read_csv(csv_path)
    accounts = rows.each_with_index.filter_map { |row, index| build_account(row, index + 1) }
    reject_duplicates(accounts)
  end

  def self.read_csv(csv_path)
    CSV.read(csv_path)
  rescue CSV::MalformedCSVError => e
    warn "AccountLoader: can't parse #{csv_path} as CSV (#{e.message})"
    []
  end
  private_class_method :read_csv

  def self.build_account(row, row_number)
    raise ArgumentError, "expected 2 columns, got #{row.length}" unless row.length == 2

    number, balance = row
    Account.new(number: number, balance: parse_balance(balance))
  rescue ArgumentError => e
    warn "AccountLoader: skipping row #{row_number} (#{e.message})"
    nil
  end
  private_class_method :build_account

  # BigDecimal's own error message quotes the bad value back verbatim - that would leak
  # real field content into the warning. Raise a generic message instead.
  def self.parse_balance(balance)
    BigDecimal(balance)
  rescue ArgumentError, TypeError
    raise ArgumentError, "balance must be a valid number"
  end
  private_class_method :parse_balance

  # First occurrence wins - a duplicate would otherwise silently overwrite the earlier
  # balance once these become a lookup hash. Warning skips the account number, same
  # reason as the other messages in this file.
  def self.reject_duplicates(accounts)
    seen_numbers = {}
    accounts.select do |account|
      if seen_numbers[account.number]
        warn "AccountLoader: skipping duplicate account number"
        false
      else
        seen_numbers[account.number] = true
        true
      end
    end
  end
  private_class_method :reject_duplicates
end
