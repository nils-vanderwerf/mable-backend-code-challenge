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
    # Guard before touching accounts - Account#debit!/#credit! raise ArgumentError on a
    # negative amount, which would otherwise crash the whole batch over one bad transfer.
    if @amount.negative?
      return TransferResult.new(transfer: self, success: false,
                                reason: TransferResult::INVALID_AMOUNT)
    end

    from_account = ledger.find(@from)
    to_account = ledger.find(@to)

    # Skip silently rather than raise - one unknown account number shouldn't
    # crash the rest of the batch.
    if from_account.nil? || to_account.nil?
      return TransferResult.new(transfer: self, success: false,
                                reason: TransferResult::ACCOUNT_NOT_FOUND)
    end

    if from_account.sufficient_funds?(@amount)
      from_account.debit!(@amount)
      to_account.credit!(@amount)
      TransferResult.new(transfer: self, success: true, reason: nil)
    else
      TransferResult.new(transfer: self, success: false, reason: TransferResult::INSUFFICIENT_FUNDS)
    end
  end
end
