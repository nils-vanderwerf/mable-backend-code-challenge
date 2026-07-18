# frozen_string_literal: true

require "csv"
require "bigdecimal"
require_relative "../transfer"

class TransferLoader
  # Same private_class_method reasoning as AccountLoader: pure functions, no shared
  # state, no need for an instance.
  def self.load(csv_path)
    rows = read_csv(csv_path)
    rows.each_with_index.filter_map { |row, index| build_transfer(row, index + 1) }
  end

  def self.read_csv(csv_path)
    CSV.read(csv_path)
  rescue CSV::MalformedCSVError => e
    warn "TransferLoader: can't parse #{csv_path} as CSV (#{e.message})"
    []
  end
  private_class_method :read_csv

  def self.build_transfer(row, row_number)
    raise ArgumentError, "expected 3 columns, got #{row.length}" unless row.length == 3

    from_acc, to_acc, amount = row
    Transfer.new(from: from_acc, to: to_acc, amount: parse_amount(amount))
  rescue ArgumentError => e
    warn "TransferLoader: skipping row #{row_number} (#{e.message})"
    nil
  end
  private_class_method :build_transfer

  # Same reasoning as AccountLoader#parse_balance - never echo the raw value back.
  def self.parse_amount(amount)
    BigDecimal(amount)
  rescue ArgumentError, TypeError
    raise ArgumentError, "amount must be a valid number"
  end
  private_class_method :parse_amount
end
