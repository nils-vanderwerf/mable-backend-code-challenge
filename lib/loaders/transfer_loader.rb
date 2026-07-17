# frozen_string_literal: true

require "csv"
require "bigdecimal"
require_relative "../transfer"

class TransferLoader
  def self.load(csv_path)
    CSV.read(csv_path).filter_map { |row| build_transfer(row) }
  end

  # A malformed row (wrong column count, non-numeric amount) shouldn't crash
  # loading every other transfer in the file - skip it and warn instead.
  def self.build_transfer(row)
    from_acc, to_acc, amount = row
    Transfer.new(from: from_acc, to: to_acc, amount: BigDecimal(amount))
  rescue ArgumentError, TypeError
    warn "TransferLoader: skipping malformed row #{row.inspect}"
    nil
  end
  private_class_method :build_transfer
end
