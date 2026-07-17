require "bigdecimal"
require_relative "../lib/transfer"
require_relative "../lib/transfer_result"
require_relative "../lib/account"
require_relative "../lib/ledger"

RSpec.describe Transfer do
  describe '#execute' do
    let(:ledger) { Ledger.new([account_one, account_two]) }
    let(:account_one) { Account.new(number: "1111234522226789", balance: BigDecimal("1000.00")) }
    let(:account_two) { Account.new(number: "1212343433335665", balance: BigDecimal("500.00")) }
    

    context 'when the sender has enough money to cover the transaction' do
      let(:transfer) { Transfer.new(from: "1111234522226789", to: "1212343433335665", amount: BigDecimal("750.00")) }
    
      it 'moves money from the sender to the recipient' do
        transfer.execute(ledger)
        expect(account_one.balance).to eq(BigDecimal("250.00"))
        expect(account_two.balance).to eq(BigDecimal("1250.00"))
      end
      it 'returns a successful TransferResult object' do
        result = transfer.execute(ledger)
        expect(result.success?).to eq(true)
        expect(result.reason).to eq(nil)
      end
    end

    context 'when the sender does not have enough money to cover the transaction' do
      let(:transfer) { Transfer.new(from: "1111234522226789", to: "1212343433335665", amount: BigDecimal("2000.00")) } 
      it "doesn't move any money" do
        transfer.execute(ledger)
        expect(account_one.balance).to eq(BigDecimal("1000.00"))
        expect(account_two.balance).to eq(BigDecimal("500.00"))
      end
      it 'returns an unsuccessful TransferResult object' do
        result = transfer.execute(ledger)
        expect(result.success?).to eq(false)
        expect(result.reason).to eq(:insufficient_funds)
      end
    end

    context "when the account looked up doesn't exist" do
      let(:no_from_account_transfer) { Transfer.new(from: "1111234522226787", to: "1212343433335665", amount: BigDecimal("2000.00")) } 
      let(:no_to_account_transfer) { Transfer.new(from: "1111234522226789", to: "1212343433335663", amount: BigDecimal("2000.00")) } 

      it "doesn't raise when the 'from' account can't be found" do
        expect { no_from_account_transfer.execute(ledger) }.not_to raise_error
        expect(account_two.balance).to eq(BigDecimal("500.00"))
      end
      it "doesn't raise when the 'to' account can't be found" do
        expect { no_to_account_transfer.execute(ledger) }.not_to raise_error
        expect(account_one.balance).to eq(BigDecimal("1000.00"))
      end
      it "returns an unsuccessful TransferResult object when the from account doesn't exist" do
        result = no_from_account_transfer.execute(ledger)
        expect(result.success?).to eq(false)
        expect(result.reason).to eq(:account_not_found)
      end
      it "returns an unsuccessful TransferResult object when the to account doesn't exist" do
        result = no_to_account_transfer.execute(ledger)
        expect(result.success?).to eq(false)
        expect(result.reason).to eq(:account_not_found)
      end
    end
  end
end