require "bigdecimal"
require_relative "../lib/account"
require_relative "../lib/transfer"
require_relative "../lib/ledger"
require_relative "../lib/transfer_result"
require_relative "../lib/console_report"

RSpec.describe ConsoleReport do
  describe '.print' do
    let(:account) { Account.new(number: "1111234522226789", balance: BigDecimal("1000.00")) }
    let(:transfer) { Transfer.new(from: "1111234522226789", to: "1212343433335665", amount: BigDecimal("750.00")) } 
    let(:ledger) { Ledger.new([account]) }
    let(:results) { [] }

    context 'when the ledger has an account with a balance' do
      it 'displays the account balance' do
        expect { ConsoleReport.print(ledger, results) }.to output(/#{account.balance.to_s('F')}/).to_stdout
      end
    end
    context 'for a successful transfer' do
      let(:successful_transfer) { TransferResult.new(transfer: transfer, success: true, reason: nil) }
      let(:successful_result) { [successful_transfer] }
      it 'displays a message for a successful transfer' do
        expect { ConsoleReport.print(ledger, successful_result) }.to output(/: successful/).to_stdout
      end
    end
    context 'for a unsuccessful transfer due to insufficient funds' do
      let(:low_fund_transfer) { TransferResult.new(transfer: transfer, success: false, reason: TransferResult::INSUFFICIENT_FUNDS) }
      let(:low_fund_result) { [low_fund_transfer] }
      it 'displays an insufficient funds message' do
        expect { ConsoleReport.print(ledger, low_fund_result) }.to output(/insufficient funds/).to_stdout
      end
    end
    context 'for a unsuccessful transfer due to an account not being found' do
      let(:no_account_transfer) { TransferResult.new(transfer: transfer, success: false, reason: TransferResult::ACCOUNT_NOT_FOUND) }
      let(:no_account_result) { [no_account_transfer] }
      it 'displays an account not found message' do
        expect { ConsoleReport.print(ledger, no_account_result) }.to output(/account not found/).to_stdout
      end
    end
  end
end