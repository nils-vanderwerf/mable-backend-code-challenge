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
  end
end
