# frozen_string_literal: true
class Transfer
  attr_reader :amount, :from, :to

  def initialize(from:, to:, amount:)
    @from = from
    @to = to
    @amount = amount
  end

  def execute(ledger)
    from_account = ledger.find(@from)
    to_account = ledger.find(@to)

    # Skip silently rather than raise - one unknown account number shouldn't
    # crash the rest of the day's batch.
    return TransferResult.new(transfer: self, success: false, reason: :account_not_found) if from_account.nil? || to_account.nil?

    if from_account.sufficient_funds?(@amount)
      from_account.debit!(@amount) 
      to_account.credit!(@amount)
      TransferResult.new(transfer: self, success: true, reason: nil)
    else
      TransferResult.new(transfer: self, success: false, reason: :insufficient_funds)
    end
  end
end