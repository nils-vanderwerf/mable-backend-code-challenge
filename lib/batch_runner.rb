# frozen_string_literal: true

require_relative "loaders/account_loader"
require_relative "loaders/transfer_loader"
require_relative "ledger"

class BatchRunner
  # .call just builds an instance and hands off to it, so the private methods
  # below have somewhere to live (a class method alone couldn't use them).
  def self.call(balances_path:, transfers_path:)
    # Named on both sides so it's clear at a glance which value goes where.
    new(balances_path: balances_path, transfers_path: transfers_path).call
  end

  def initialize(balances_path:, transfers_path:)
    @balances_path = balances_path
    @transfers_path = transfers_path
  end

  def call
    { results: transfer_results, ledger: ledger }
  end

  private

  # Memoized with @ledger ||= - build it once, reuse it after. Without this, every call
  # would build a brand new Ledger from the CSV again, wiping out any transfers already applied.
  def ledger
    @ledger ||= Ledger.new(AccountLoader.load(@balances_path))
  end

  # loads the transfers csv and runs each one against the ledger above
  def transfer_results
    TransferLoader.load(@transfers_path).map { |transfer| transfer.execute(ledger) }
  end
end
