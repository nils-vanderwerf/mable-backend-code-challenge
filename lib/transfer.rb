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
    from_account = ledger.find(@from)
    to_account = ledger.find(@to)

    # Skip silently rather than raise - one unknown account number shouldn't
    # crash the rest of the batch.
    return TransferResult.new(transfer: self, success: false, reason: TransferResult::ACCOUNT_NOT_FOUND) if from_account.nil? || to_account.nil?

    if from_account.sufficient_funds?(@amount)
      from_account.debit!(@amount) 
      to_account.credit!(@amount)
      TransferResult.new(transfer: self, success: true, reason: nil)
    else
      TransferResult.new(transfer: self, success: false, reason: TransferResult::INSUFFICIENT_FUNDS)
    end
  end
end