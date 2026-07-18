# frozen_string_literal: true

class Account
  # Last-line-of-defense: Transfer should check sufficient_funds? before calling debit!.
  class InsufficientFundsError < StandardError; end

  # Read-only: only credit!/debit! may change the balance, to enforce the invariant.
  attr_reader :balance, :number

  def initialize(number:, balance:)
    # Doesn't include the account number in the error - same PII reasoning as debit!'s
    # error below.
    unless number.is_a?(String) && number.match?(/\A\d{16}\z/)
      raise ArgumentError, "account number must be a 16 digit number"
    end

    @number = number
    @balance = balance
  end

  def credit!(amount)
    # Protects against negative input silently making the balance negative.
    raise ArgumentError, "amount must not be negative" if amount.negative?

    @balance += amount
  end

  def debit!(amount)
    # Protects against negative input silently increasing the balance instead of debiting it.
    raise ArgumentError, "amount must not be negative" if amount.negative?

    # Check funds before subtracting, so a failed debit leaves @balance untouched.
    # to_s('F') keeps the message readable (BigDecimal's default is scientific notation).
    unless sufficient_funds?(amount)
      raise InsufficientFundsError,
            "Can't debit amount of #{amount.to_s('F')} for this account because the balance is " \
            "currently #{@balance.to_s('F')} and would become negative"
    end

    @balance -= amount
  end

  def sufficient_funds?(amount)
    # positive or zero
    !(@balance - amount).negative?
  end
end
