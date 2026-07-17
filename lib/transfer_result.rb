# frozen_string_literal: true

class TransferResult
  INSUFFICIENT_FUNDS = :insufficient_funds
  ACCOUNT_NOT_FOUND = :account_not_found
  
  attr_reader :transfer, :success, :reason

  def initialize(transfer:, success:, reason: nil)
    @transfer = transfer
    @success = success
    @reason = reason
  end

  def success?
    success
  end
end