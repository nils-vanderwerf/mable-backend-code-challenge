# frozen_string_literal: true

require_relative "../lib/batch_runner"
require_relative "../lib/console_report"
require 'pry'

# Optional CLI args for a different day's CSVs; with none given, falls back
# to the sample files provided with this project.
balances_path = ARGV[0] || File.expand_path("../data/mable_account_balances.csv", __dir__)
transfers_path = ARGV[1] || File.expand_path("../data/mable_transactions.csv", __dir__)

# Check the files exist first - a bad path would otherwise crash with a raw Errno::ENOENT.
[balances_path, transfers_path].each do |path|
  unless File.exist?(path)
    warn "Can't find file: #{path}"
    exit 1
  end
end

batch = BatchRunner.call(balances_path: balances_path, transfers_path: transfers_path)

ConsoleReport.print(batch[:ledger], batch[:results])
