# frozen_string_literal: true
require_relative "loaders/account_loader"
require_relative "loaders/transfer_loader"
require_relative "ledger"

class BatchRunner
  # .call is just the public entry point, hands off to a real instance
  # straight away so the private methods below actually work
  def self.call(balances_path, transfers_path)
    new(balances_path, transfers_path).call
  end

  def initialize(balances_path, transfers_path)
    @balances_path = balances_path
    @transfers_path = transfers_path
  end

  def call
    { results: transfer_results, ledger: ledger }
  end

  private

  # builds the ledger once from the balances csv
  # need to memoize it because otherwise it will build a new ledger from scratch, instead of the transfers' effects 

  def ledger
    @ledger ||= Ledger.new(AccountLoader.load(@balances_path))
  end

  # loads the transfers csv and runs each one against the ledger above
  def transfer_results
    TransferLoader.load(@transfers_path).map { |transfer| transfer.execute(ledger) }
  end
end
