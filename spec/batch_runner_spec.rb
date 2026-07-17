require "bigdecimal"
require_relative "../lib/batch_runner"

RSpec.describe BatchRunner do
  describe '.call' do
    let(:balances_path) { "spec/fixtures/balances.csv" }
    let(:transfers_path) { "spec/fixtures/transactions.csv" }

    it 'creates a hash with TransferResults and the ledgers for the account' do
      batch = BatchRunner.call(balances_path, transfers_path)
      expect(batch[:results].length).to eq(2)
      expect(batch[:ledger]).to be_an_instance_of(Ledger)
    end
    # integration tests
    context 'when run against the real provided CSVs' do
      let(:real_balances_path) { "mable_account_balances.csv" }
      let(:real_transfers_path) { "mable_transactions.csv" }
      
      it 'returns the correct balance' do
        batch = BatchRunner.call(real_balances_path, real_transfers_path)

        expect(batch[:ledger].find("1111234522226789").balance).to eq(BigDecimal("4820.50"))
        expect(batch[:ledger].find("1111234522221234").balance).to eq(BigDecimal("9974.40"))
        expect(batch[:ledger].find("2222123433331212").balance).to eq(BigDecimal("1550.00"))
        expect(batch[:ledger].find("1212343433335665").balance).to eq(BigDecimal("1725.60"))
        expect(batch[:ledger].find("3212343433335755").balance).to eq(BigDecimal("48679.50"))
      end
    end
    context 'when a batch includes failures' do
      let(:transfer_failures_path) { 'spec/fixtures/transfers_with_failures.csv' }

      it 'processes each transfer independently and reports the outcome' do
        batch = BatchRunner.call(balances_path, transfer_failures_path)

        successful_result, insufficient_funds_result, account_not_found_result = batch[:results]

        expect(successful_result.success?).to eq(true)
        expect(successful_result.reason).to eq(nil)

        expect(insufficient_funds_result.success?).to eq(false)
        expect(insufficient_funds_result.reason).to eq(TransferResult::INSUFFICIENT_FUNDS)

        expect(account_not_found_result.success?).to eq(false)
        expect(account_not_found_result.reason).to eq(TransferResult::ACCOUNT_NOT_FOUND)
      end
    end
  end
end
