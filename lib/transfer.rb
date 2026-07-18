# frozen_string_literal: true

require_relative "transfer_result"

class Transfer
  attr_reader :from, :to, :amount

  def initialize(from:, to:, amount:)
    @from = from
    @to = to
    @amount = amount
  end

  def execute(ledger)
    # Check this first - debit!/credit! would raise on a negative amount, which would
    # crash the whole batch instead of just skipping this one transfer.
    return failure(TransferResult::INVALID_AMOUNT) if @amount.negative?

    from_account = ledger.find(@from)
    to_account = ledger.find(@to)
    # Skip silently rather than raise - one unknown account number shouldn't
    # crash the rest of the batch.
    return failure(TransferResult::ACCOUNT_NOT_FOUND) if from_account.nil? || to_account.nil?
    return failure(TransferResult::INSUFFICIENT_FUNDS) unless from_account.sufficient_funds?(@amount)

    from_account.debit!(@amount)
    to_account.credit!(@amount)
    TransferResult.new(transfer: self, success: true, reason: nil)
  end

  private

  def failure(reason)
    TransferResult.new(transfer: self, success: false, reason: reason)
  end
end
