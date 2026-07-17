# frozen_string_literal: true

class Account
  # Last-line-of-defense: Transfer should check sufficient_funds? before calling debit!.
  class InsufficientFundsError < StandardError; end

  # Read-only: only credit!/debit! may change the balance, to enforce the invariant.
  attr_reader :balance, :number

  def initialize(number:, balance:)
    # Checks for a 16 digit number, Message omits the number itself
    # same PII reasoning as debit!'s InsufficientFundsError.
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

    # Check before mutating so a failed debit leaves @balance untouched.
    # to_s('F') avoids BigDecimal's scientific notation; account number omitted (could hit logs).
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
