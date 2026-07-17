# Mable Back End Code Challenge

A simple banking system: load a company's account balances from a CSV, then apply a day's transfers from another CSV. A transfer that would overdraw an account, or references an account number that doesn't exist, gets skipped and reported - the rest of the batch still runs.

## Setup

```
bundle install
```

Needs Ruby >= 3.1 (built and tested on 3.1.0p0).

## Running the tests

```
bundle exec rspec
```

## Running it

```
ruby bin/run.rb
```

Runs the provided `mable_account_balances.csv` / `mable_transactions.csv` at the project root and prints a report: final balances, one line per transfer with its outcome, and a summary count.

Example output from a mixed batch (success, insufficient funds, account not found, invalid amount all in one run):

![Console output showing final balances and per-transfer outcomes](docs/console_output.png)

## Assumptions

- **Output format**: console summary for now (final balances + a success/fail line per transfer). Can swap for a CSV writer later if that's preferred.
- **Unknown account number** (either side of a transfer): skip that transfer, keep processing the rest of the batch, report it as `account_not_found` - kept separate from insufficient funds rather than lumped in with it.
- **Overdraft** (balance would go below $0): skip just that transfer, report `insufficient_funds`, keep processing the rest.
- **Money** is always `BigDecimal`, never `Float` - avoids cent-level rounding drift across a batch of transfers.
- **Scope**: single company, single ledger, matching the brief. Not designed for multiple companies unless that's actually needed.

## Testing

Loader specs run against small fixture CSVs in `spec/fixtures/`, not the provided sample data - keeps those tests decoupled from anything unrelated to parsing. `BatchRunner`'s spec covers three integration scenarios: a small fixture (basic wiring), the real provided CSVs (final balances match the hand-verified table below), and `spec/fixtures/transfers_with_failures.csv` (a mixed batch - success, insufficient funds, and an unknown account number in one run) since the provided sample data is entirely happy-path.

### Expected result for the provided sample data

| Account | Start | End |
|---|---:|---:|
| 1111234522226789 | 5000.00 | 4820.50 |
| 1111234522221234 | 10000.00 | 9974.40 |
| 2222123433331212 | 550.00 | 1550.00 |
| 1212343433335665 | 1200.00 | 1725.60 |
| 3212343433335755 | 50000.00 | 48679.50 |

All four sample transfers succeed - asserted directly in `spec/batch_runner_spec.rb`.

## Design

- `Account` - balance plus the one rule that can never break: it can't go negative.
- `Transfer` - a requested move of money between two account numbers. `#execute(ledger)` does the work and returns a `TransferResult`. Also guards against a negative amount up front, failing gracefully rather than letting `Account` raise and crash the batch.
- `TransferResult` - what happened to a transfer: success or not, and why if not.
- `Ledger` - a lookup table, account number -> `Account`.
- `AccountLoader` / `TransferLoader` - turn the CSV files into the objects above, skipping and warning on any malformed row rather than failing the whole file.
- `BatchRunner` - orchestrates a full run: builds the `Ledger`, loads the transfers, executes each one, hands back `{ results:, ledger: }`. `.call` is a thin wrapper that delegates to a short-lived instance, so private helper methods have somewhere to live.
- `ConsoleReport` - prints the result: final balances, per-transfer outcomes, a summary count.
- `bin/run.rb` - entry point, wires real file paths to `BatchRunner` + `ConsoleReport`.

**A design detail**: `BatchRunner`/`ConsoleReport` need private helpers that share state across calls (e.g. the file paths passed in), so their `.call`/`.print` class methods delegate immediately to a short-lived instance - ordinary `private` instance methods then just work. `AccountLoader`/`TransferLoader`'s row-building helpers need no state at all (pure functions of a single CSV row), so they use `private_class_method` instead - no instance required. Same problem, two different tools, chosen by what the helper actually needs.
