# frozen_string_literal: true
class ConsoleReport
  SUCCESS_LABEL = "successful".freeze
  INSUFFICIENT_FUNDS_LABEL = "unsuccessful - insufficient funds".freeze
  ACCOUNT_NOT_FOUND_LABEL = "unsuccessful - account not found".freeze

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
      label = case result.reason
              when nil
                SUCCESS_LABEL
              when TransferResult::INSUFFICIENT_FUNDS
                INSUFFICIENT_FUNDS_LABEL
              when TransferResult::ACCOUNT_NOT_FOUND
                ACCOUNT_NOT_FOUND_LABEL
              end
      puts "Transfer of $#{transfer.amount.to_s('F')} from #{transfer.from} to #{transfer.to}: Transfer was #{label}"
    end
  end
end
