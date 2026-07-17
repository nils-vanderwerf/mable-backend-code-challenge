# frozen_string_literal: true
class Ledger
  def initialize(accounts)
    # turn the accounts array into a number => account hash once, so find doesn't have to loop every time
    @accounts = accounts.each_with_object({}) do |account, hash|
      hash[account.number] = account
    end
  end

  def find(number)
    # just returns nil if the account isn't there, no need to raise
    @accounts[number]
  end
end