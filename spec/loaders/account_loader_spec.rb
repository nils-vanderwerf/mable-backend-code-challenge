# frozen_string_literal: true

require_relative "../../lib/loaders/account_loader"
require_relative "../../lib/account"

RSpec.describe AccountLoader do
  describe ".load" do
    let(:csv_path) { "spec/fixtures/balances.csv" }

    it "returns an array of Accounts built from the CSV rows" do
      accounts = AccountLoader.load(csv_path)
      expect(accounts.length).to eq(2)
      expect(accounts.first.number).to eq("1111111111111111")
      expect(accounts.first.balance).to eq(BigDecimal("1000.00"))
    end

    context "when a row is malformed" do
      let(:csv_path) { "spec/fixtures/balances_with_malformed_row.csv" }

      it "skips the bad row instead of crashing the whole load, and warns about it" do
        accounts = nil
        expect { accounts = AccountLoader.load(csv_path) }.to output(/skipping malformed row/).to_stderr
        expect(accounts.length).to eq(1)
        expect(accounts.first.number).to eq("1111111111111111")
      end
    end
  end
end
