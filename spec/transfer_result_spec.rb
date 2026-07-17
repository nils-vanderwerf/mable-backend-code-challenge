require "bigdecimal"
require_relative "../lib/transfer_result"
require_relative "../lib/transfer"
require_relative "../lib/account"

RSpec.describe TransferResult do
  describe '#success?' do
    let(:transfer) { Transfer.new(from: "1111234522226789", to: "1212343433335665", amount: BigDecimal("750.00")) } 
    context 'when a transfer is successful' do
      let(:result) { TransferResult.new(transfer: transfer, success: true, reason: nil) }

      it 'returns true' do
        expect(result.success?).to eq(true)
      end
      it 'does not need a reason' do
        expect(result.reason).to eq(nil)
      end
    end
    context 'when a transfer is unsuccessful' do
      let(:result) { TransferResult.new(transfer: transfer, success: false, reason: :insufficient_funds) }

      it 'returns false' do
        expect(result.success?).to eq(false)
      end
      it 'provides a reason' do
        expect(result.reason).to eq(:insufficient_funds)
      end
    end
  end
end