# frozen_string_literal: true

class TransferResult
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