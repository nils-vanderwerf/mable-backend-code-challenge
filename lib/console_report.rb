# frozen_string_literal: true

require_relative "transfer_result"

class ConsoleReport
  SUCCESS_LABEL = "successful"
  INSUFFICIENT_FUNDS_LABEL = "unsuccessful - insufficient funds"
  ACCOUNT_NOT_FOUND_LABEL = "unsuccessful - account not found"
  INVALID_AMOUNT_LABEL = "unsuccessful - invalid amount"

  REASON_LABELS = {
    nil => SUCCESS_LABEL,
    TransferResult::INSUFFICIENT_FUNDS => INSUFFICIENT_FUNDS_LABEL,
    TransferResult::ACCOUNT_NOT_FOUND => ACCOUNT_NOT_FOUND_LABEL,
    TransferResult::INVALID_AMOUNT => INVALID_AMOUNT_LABEL
  }.freeze

  def self.print(ledger, results)
    new(ledger, results).print
  end

  def initialize(ledger, results)
    @ledger = ledger
    @results = results
  end

  def print
    puts "\nProcessing today's transfers..."
    puts "=== Daily Transfer Batch ==="
    print_balances
    puts "\nTransfer results:"
    print_transfer_results
    puts "\nBatch complete: #{@results.count(&:success?)}/#{@results.length} transfers succeeded.\n"
  end

  private

  def print_balances
    # print each account number and its balance in the ledger
    @ledger.all.each do |account|
      puts "The balance for ACCOUNT: #{account.number} is: $#{account.balance.to_s('F')}"
    end
  end

  def print_transfer_results
    @results.each do |result|
      transfer = result.transfer
      puts "Transfer of #{format_amount(transfer.amount)} from #{transfer.from} to #{transfer.to}: " \
           "Transfer was #{label_for(result.reason)}"
    end
  end

  def label_for(reason)
    # #fetch returns the matching label if reason is a known key; otherwise it runs the
    # block and returns that instead. Unlike #[], a missing key can't silently become nil.
    # The block form (vs a 2nd #fetch arg) only builds the fallback string if it's actually needed.
    REASON_LABELS.fetch(reason) { "unsuccessful - unknown reason (#{reason.inspect})" }
  end

  # Transfer#execute's guard stops a negative amount from being acted on (no debit!/credit!
  # happens) - not from being reported. A rejected transfer still shows its real amount here,
  # so this branch is reachable. Minus sign goes before the $, not between it and the digits.
  def format_amount(amount)
    amount.negative? ? "-$#{amount.abs.to_s('F')}" : "$#{amount.to_s('F')}"
  end
end
