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

Not finished yet - `bin/run.rb` is still being built.

## Assumptions

- **Output format**: console summary for now (final balances + a success/fail line per transfer). Can swap for a CSV writer later if that's preferred.
- **Unknown account number** (either side of a transfer): skip that transfer, keep processing the rest of the batch, report it as `account_not_found` - kept separate from insufficient funds rather than lumped in with it.
- **Overdraft** (balance would go below $0): skip just that transfer, report `insufficient_funds`, keep processing the rest.
- **Money** is always `BigDecimal`, never `Float` - avoids cent-level rounding drift across a batch of transfers.
- **Scope**: single company, single ledger, matching the brief. Not designed for multiple companies unless that's actually needed.

## Testing

Loader specs run against small fixture CSVs in `spec/fixtures/`, not the provided sample data - keeps those tests decoupled from anything unrelated to parsing. The provided `mable_account_balances.csv` / `mable_transactions.csv` are used in the integration test instead, to prove the whole system against the real data end to end.

## Known limitations

- `AccountLoader` doesn't validate its input - it assumes each CSV row is well-formed (right number of columns, a valid number for the balance). A malformed row would raise a raw CSV/BigDecimal error rather than a clear one. Deliberate scope cut for the time-box, would add with more time.

## Design

- `Account` - balance plus the one rule that can never break: it can't go negative.
- `Transfer` - a requested move of money between two account numbers. `#execute(ledger)` does the work and returns a `TransferResult`.
- `TransferResult` - what happened to a transfer: success or not, and why if not.
- `Ledger` - a lookup table, account number -> `Account`.
- `AccountLoader` / `TransferLoader` - turn the CSV files into the objects above.
- `BatchRunner` - orchestrates a full run: builds the `Ledger`, loads the transfers, executes each one, hands back `{ results:, ledger: }`. `.call` is a thin wrapper that delegates to a short-lived instance, so private helper methods have somewhere to live.
- `ConsoleReport` - prints the result. Not built yet.
