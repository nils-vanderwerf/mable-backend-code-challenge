# frozen_string_literal: true

require_relative "../lib/batch_runner"
require_relative "../lib/console_report"

balances_path = File.expand_path("../mable_account_balances.csv", __dir__)
transfers_path = File.expand_path("../mable_transactions.csv", __dir__)

batch = BatchRunner.call(balances_path, transfers_path)

ConsoleReport.print(batch[:ledger], batch[:results])
