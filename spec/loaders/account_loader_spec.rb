require_relative "../../lib/loaders/account_loader"
require_relative "../../lib/account"

RSpec.describe AccountLoader do
  describe '.load' do
    let(:csv_path) { "spec/fixtures/balances.csv" }

     it 'returns an array of Accounts built from the CSV rows' do
      accounts = AccountLoader.load(csv_path)
      expect(accounts.length).to eq(2)
      expect(accounts.first.number).to eq("1111111111111111")
      expect(accounts.first.balance).to eq(BigDecimal("1000.00"))
     end
  end
end
