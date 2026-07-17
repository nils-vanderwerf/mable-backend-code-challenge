require_relative "../lib/account"

RSpec.describe Account do
  describe '#balance' do
    context 'when provided with an account number and a balance' do
      let(:account) { Account.new(number: "1111234522226789", balance: BigDecimal("5000.00")) }
      it 'reports that balance' do
        expect(account.balance).to eq(BigDecimal("5000.00"))
      end
    end
  end
  describe '#credit!' do
    let(:account) { Account.new(number: "1111234522226789", balance: BigDecimal("100.0")) }
    context 'when an amount is credited to the account' do
      it 'updates the current balance' do
        account.credit!(BigDecimal("50.00"))
        expect(account.balance).to eq(BigDecimal("150.00"))
      end
    end
    context 'when a negative amount is credited to the account' do
      it 'raises an error and leaves the balance untouched' do
        expect { account.credit!(BigDecimal("-50.00")) }.to raise_error(ArgumentError, "amount must not be negative")
        expect(account.balance).to eq(BigDecimal("100.0"))
      end
    end
  end
  describe '#debit!' do
    let(:account) { Account.new(number: "1111234522226789", balance: BigDecimal("100.0")) }
    context 'when an amount is debited from the account and the remaining amount is greater than zero' do
      it 'updates the current balance' do
        account.debit!(BigDecimal("50.0"))
        expect(account.balance).to eq(BigDecimal("50.0"))
      end
    end
    context 'when an amount attempts to be debited from the account and the remaining amount is negative' do
      it 'raises an error' do
        amount = BigDecimal("150.0")

        # 100.0 hardcoded (not account.balance) so the assertion isn't tested against itself.
        expect { account.debit!(amount) }.to raise_error(Account::InsufficientFundsError, /^Can't debit amount of #{amount.to_s('F')} for this account because the balance is currently 100.0 and would become negative/)
        expect(account.balance).to eq(BigDecimal("100.0")) # untouched after a failed debit
      end
    end
    # Malformed input (ArgumentError), distinct from the InsufficientFundsError case above.
    context 'when a negative amount is debited from the account' do
      it 'raises an error and leaves the balance untouched' do
        expect { account.debit!(BigDecimal("-50.00")) }.to raise_error(ArgumentError, "amount must not be negative")
        expect(account.balance).to eq(BigDecimal("100.0"))
      end
    end
  end

  describe '#sufficient_funds?' do
    let(:account) { Account.new(number: "1111234522226789", balance: BigDecimal("100.0")) }
    context 'when an amount is debited from the balance that makes it positive' do
      it 'returns true' do
        expect(account.sufficient_funds?(BigDecimal("50.00"))).to be true
      end
    end
    context 'when an amount equals the balance exactly' do
      it 'returns true' do
        expect(account.sufficient_funds?(BigDecimal("100.00"))).to be true
      end
    end
    context 'when an amount is debited from the balance that makes it negative' do
      it 'returns true' do
        expect(account.sufficient_funds?(BigDecimal("150.00"))).to be false
      end
    end
  end

end
