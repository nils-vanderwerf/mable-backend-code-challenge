# frozen_string_literal: true

require "csv"
require "bigdecimal"
require_relative "../account"

class AccountLoader
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

  # Never echoes the raw value - BigDecimal's own error message does that, which would
  # leak field content (from this file, or an unrelated one if a path pointed elsewhere).
  def self.parse_balance(balance)
    BigDecimal(balance)
  rescue ArgumentError, TypeError
    raise ArgumentError, "balance must be a valid number"
  end
  private_class_method :parse_balance

  # First occurrence wins - a repeat would otherwise silently overwrite an earlier
  # balance once Ledger turns these into a number => account lookup hash. Doesn't log
  # the account number itself, same reasoning as InsufficientFundsError's message.
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
