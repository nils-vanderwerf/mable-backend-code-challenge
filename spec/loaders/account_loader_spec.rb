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
        expect { accounts = AccountLoader.load(csv_path) }.to output(/skipping row \d+/).to_stderr
        expect(accounts.length).to eq(1)
        expect(accounts.first.number).to eq("1111111111111111")
      end
    end

    context "when a row's account number isn't 16 digits" do
      let(:csv_path) { "spec/fixtures/balances_with_bad_account_number.csv" }

      it "skips the bad row instead of crashing the whole load, and warns about it" do
        accounts = nil
        expect { accounts = AccountLoader.load(csv_path) }.to output(/skipping row \d+/).to_stderr
        expect(accounts.length).to eq(1)
        expect(accounts.first.number).to eq("1111111111111111")
      end
    end

    context "when every row has the wrong number of columns" do
      # A transfers CSV (3 columns) loaded by mistake as balances (2 columns) - without
      # the column count check, this would silently misread the 2nd account number as
      # a balance instead of being rejected.
      let(:csv_path) { "spec/fixtures/transactions.csv" }

      it "skips every row instead of misreading a column as the balance" do
        accounts = nil
        expect { accounts = AccountLoader.load(csv_path) }.to output(/skipping row \d+/).to_stderr
        expect(accounts).to eq([])
      end
    end

    context "when an account number appears more than once" do
      let(:csv_path) { "spec/fixtures/balances_with_duplicate_account_number.csv" }

      it "keeps the first balance and skips the repeat instead of silently overwriting it" do
        accounts = nil
        expect { accounts = AccountLoader.load(csv_path) }.to output(/skipping duplicate account number/).to_stderr
        expect(accounts.length).to eq(2)
        expect(accounts.first.number).to eq("1111111111111111")
        expect(accounts.first.balance).to eq(BigDecimal("1000.00"))
      end
    end

    context "when the file isn't valid CSV syntax at all" do
      let(:csv_path) { "spec/fixtures/invalid_csv_syntax.csv" }

      it "fails cleanly instead of crashing with a raw CSV::MalformedCSVError" do
        accounts = nil
        expect { accounts = AccountLoader.load(csv_path) }.to output(/can't parse .* as CSV/).to_stderr
        expect(accounts).to eq([])
      end
    end
  end
end
