# frozen_string_literal: true

class Ledger
  def initialize(accounts)
    # build a number => account hash once, so find is a lookup instead of a search
    @accounts = accounts.to_h do |account|
      [account.number, account]
    end
  end

  def find(number)
    # just returns nil if the account isn't there, no need to raise
    @accounts[number]
  end

  # used by ConsoleReport to list every account's final balance
  def all
    @accounts.values
  end
end
