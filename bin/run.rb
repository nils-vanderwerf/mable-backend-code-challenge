# frozen_string_literal: true

require_relative "../lib/batch_runner"
require_relative "../lib/console_report"

# Optional CLI args for a different day's CSVs (ruby bin/run.rb balances.csv transfers.csv).
# With no args, falls back to the two sample files provided with this project.
balances_path = ARGV[0] || File.expand_path("../mable_account_balances.csv", __dir__)
transfers_path = ARGV[1] || File.expand_path("../mable_transactions.csv", __dir__)

# A typo'd path from the command line would otherwise crash with a raw Errno::ENOENT.
[balances_path, transfers_path].each do |path|
  unless File.exist?(path)
    warn "Can't find file: #{path}"
    exit 1
  end
end

batch = BatchRunner.call(balances_path: balances_path, transfers_path: transfers_path)

ConsoleReport.print(batch[:ledger], batch[:results])
