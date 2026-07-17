require_relative "../lib/batch_runner"
require_relative "../lib/console_report"

balances_path = File.expand_path("../mable_account_balances.csv", __dir__)
transfers_path = File.expand_path("../mable_transactions.csv", __dir__)

result = BatchRunner.call(balances_path, transfers_path)

ConsoleReport.print(result[:ledger], result[:results])