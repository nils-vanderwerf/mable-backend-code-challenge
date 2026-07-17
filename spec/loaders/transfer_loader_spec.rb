# frozen_string_literal: true

require "bigdecimal"
require_relative "../../lib/loaders/transfer_loader"
require_relative "../../lib/transfer"

RSpec.describe TransferLoader do
  describe ".load" do
    let(:csv_path) { "spec/fixtures/transactions.csv" }

    it "returns an array of Transfers built from the CSV rows" do
      transfers = TransferLoader.load(csv_path)
      expect(transfers.length).to eq(2)
      expect(transfers.first.from).to eq("1111111111111111")
      expect(transfers.first.to).to eq("2222222222222222")
      expect(transfers.first.amount).to eq(BigDecimal("1000.00"))
    end

    context "when a row is malformed" do
      let(:csv_path) { "spec/fixtures/transactions_with_malformed_row.csv" }

      it "skips the bad row instead of crashing the whole load, and warns about it" do
        transfers = nil
        expect { transfers = TransferLoader.load(csv_path) }.to output(/skipping row \d+/).to_stderr
        expect(transfers.length).to eq(1)
        expect(transfers.first.amount).to eq(BigDecimal("1000.00"))
      end
    end

    context "when every row has the wrong number of columns" do
      # A balances CSV (2 columns) loaded by mistake as transfers (3 columns) - without
      # the column count check, this would silently read a nil amount instead of being
      # rejected.
      let(:csv_path) { "spec/fixtures/balances.csv" }

      it "skips every row instead of misreading a nil amount" do
        transfers = nil
        expect { transfers = TransferLoader.load(csv_path) }.to output(/skipping row \d+/).to_stderr
        expect(transfers).to eq([])
      end
    end

    context "when the file isn't valid CSV syntax at all" do
      let(:csv_path) { "spec/fixtures/invalid_csv_syntax.csv" }

      it "fails cleanly instead of crashing with a raw CSV::MalformedCSVError" do
        transfers = nil
        expect { transfers = TransferLoader.load(csv_path) }.to output(/can't parse .* as CSV/).to_stderr
        expect(transfers).to eq([])
      end
    end
  end
end
