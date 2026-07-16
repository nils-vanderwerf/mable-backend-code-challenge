require "bigdecimal"
require_relative "../lib/ledger"
require_relative "../lib/account"

RSpec.describe Ledger do
  describe '#find' do
    let(:account_one) { Account.new(number: "1111234522226789", balance: BigDecimal("1000.00")) }
    let(:account_two) { Account.new(number: "1212343433335665", balance: BigDecimal("500.00")) }
    let(:ledger) { Ledger.new([account_one, account_two]) }

    context 'when the account number exists' do
      it 'returns the matching account' do
        expect(ledger.find("1111234522226789")).to eq(account_one)
      end
    end
    context "when the account number doesn't exist" do
      it 'returns nil' do
        expect(ledger.find("0000000000000000")).to eq(nil)
      end
    end
  end
end