# Implementation Plan — Mable Back End Code Test

Goal: model a single company's daily transfer batch (load balances → replay
transfers in order → refuse anything that overdraws → report the result).
Scope stays to what the brief actually asks for, inside a 2–4 hour window —
readable, well-separated, tested, nothing built beyond what's needed.

*Paired with Claude Code throughout — see README.md and Build order below
for how that was scoped.*

## Decisions already made

| Question | Decision |
|---|---|
| Output format | Console summary: final balances + per-transfer success/fail line. Confirmed with interviewer, easy to swap for a CSV writer later if he'd prefer. |
| Transfer to/from an unknown account number | Skip it, keep processing the rest of the batch, report a distinct `account_not_found` reason (not conflated with insufficient funds). |
| Overdraft (balance would go below $0) | Skip that transfer only, record `insufficient_funds`, keep processing the rest of the file. |
| Money type | `BigDecimal`, never `Float` — avoids cent-level rounding drift. |
| Scope | Single company, single ledger — matches the brief. Not designing for multi-company unless interviewer says otherwise. |
| Duplicate account number in the balances file | Keep the first occurrence, skip and warn on the rest. One account can only hold one balance, so if two rows disagree, one figure gets discarded no matter which side wins — that part can't be avoided. What the warning actually buys: (1) **consistency** — the same rule applies every time, not a random pick, and (2) **visibility** — a human finds out two rows disagreed and can go check which one was actually right. It doesn't prevent data loss; it prevents that loss from being silent. |

## Domain model

| Class | Responsibility | Not responsible for |
|---|---|---|
| `Account` | Owns `number` + `balance`. Enforces the one invariant that must never break: balance can't be debited below zero. Exposes `sufficient_funds?`, `credit!`, `debit!`. Starting balance isn't validated at construction — trusts the input data. | Deciding *what to do* when funds are insufficient — that's policy, not invariant. |
| `Transfer` | A requested move of money (`from`, `to`, `amount`). `#execute(ledger)` rejects a negative amount outright, then looks up both accounts, checks funds, applies the debit/credit, and returns a `TransferResult`. This is where the "skip & report" policy actually lives. | Parsing CSV, printing anything. |
| `TransferResult` | Read-only value object (plain class, `attr_reader` only — no setters, nothing mutates after construction): the transfer, `success?`, and a `reason` (`nil`, `:insufficient_funds`, `:account_not_found`, `:invalid_amount`). | Formatting output for a human. |
| `Ledger` | A registry of accounts (`Hash` of number → `Account`) with `#find(number)`. | Business rules — it's just a lookup table. |
| `AccountLoader` | Parses `mable_account_balances.csv` rows into `Account` objects. | Anything about transfers. |
| `TransferLoader` | Parses `mable_transactions.csv` rows into `Transfer` objects. | Anything about accounts. |
| `BatchRunner` | Orchestrates: build the ledger, load transfers, run each `Transfer#execute`, collect results. | Printing — it hands results back, doesn't format them. |
| `ConsoleReport` | Takes the ledger + results, prints final balances and per-transfer outcomes. | Any business logic. |
| `bin/run.rb` | Entry point — wires file paths to `BatchRunner` + `ConsoleReport`. | Everything else. |

Why split `Ledger` from `Transfer`, and `BatchRunner` from `ConsoleReport`? A
lookup table shouldn't know business rules, and an orchestrator shouldn't
know how to format a string for a terminal. Each class should be explainable
in one sentence — if it takes more than that, it's doing too much.

## Project structure

```
mable_back_end_code_test/
├── Gemfile
├── README.md                    # assumptions, how to run, how to test
├── IMPLEMENTATION_PLAN.md        # this file
├── bin/
│   └── run.rb
├── lib/
│   ├── account.rb
│   ├── transfer.rb
│   ├── transfer_result.rb
│   ├── ledger.rb
│   ├── console_report.rb
│   ├── batch_runner.rb
│   └── loaders/
│       ├── account_loader.rb
│       └── transfer_loader.rb
└── spec/
    ├── spec_helper.rb
    ├── account_spec.rb
    ├── transfer_spec.rb
    ├── transfer_result_spec.rb
    ├── ledger_spec.rb
    ├── console_report_spec.rb
    ├── batch_runner_spec.rb      # integration, uses provided CSVs
    ├── loaders/
    │   ├── account_loader_spec.rb
    │   └── transfer_loader_spec.rb
    └── fixtures/
        ├── balances.csv
        ├── balances_with_bad_account_number.csv
        ├── balances_with_duplicate_account_number.csv
        ├── balances_with_malformed_row.csv
        ├── invalid_csv_syntax.csv
        ├── transactions.csv
        ├── transactions_with_malformed_row.csv
        └── transfers_with_failures.csv   # exercises both failure paths against real-shaped data
```

## Modern Ruby conventions to apply

- `# frozen_string_literal: true` at the top of every file.
- Keyword-argument `initialize` + `attr_reader` throughout. `TransferResult`
  is read-only from the outside (no setters, nothing to mutate after
  construction); `Account`/`Transfer` add real mutating methods (`credit!`/
  `debit!`, `#execute`) on top of the same base pattern.
- Keyword arguments on multi-arg initializers (`Account.new(number:, balance:)`)
  — self-documenting at the call site, order-independent.
- `BigDecimal` for all money; parse straight out of the CSV string, never via
  `Float`.
- Small methods, one level of abstraction each — if a method mixes "loop over
  rows" and "parse a row," that's two methods.
- Prefer a guard clause + early return over nested conditionals.
- No comments explaining *what* the code does — names should carry that. A
  comment is only earned by a non-obvious *why* (e.g. why `BigDecimal` over
  `Float`).
- One exception class, `Account::InsufficientFundsError`, used only as a
  last-line-of-defense invariant guard inside `Account#debit!` — not used for
  normal control flow. `Transfer#execute` checks `sufficient_funds?` *before*
  calling `debit!`, so the exception should never actually fire in practice;
  it's there so `Account` can never silently go negative even if a future
  caller forgets the check.

## Build order (test-first, one class at a time)

Rough time-box for a 2–4 hour session. Claude Code paired on this as a
discipline-enforcement tool, not a code generator: write the failing test
first, predict red/green before running it, explain the reasoning out loud
before moving to the next class. Design decisions and the actual
implementation stayed mine — the value was catching skipped steps and
mistakes early, not writing logic.

1. **Scaffold** (~15 min) — `Gemfile` (rspec, bigdecimal — the rest is
   stdlib), `spec_helper.rb`, directory structure, confirm `bundle exec rspec`
   runs with zero examples.
2. **`Account`** (~45 min) — starting balance, `credit!` increases it,
   `debit!` decreases it, `sufficient_funds?` predicate, `debit!` guards the
   invariant even if called directly with too large an amount.
3. **`Transfer` + `TransferResult`** (~45 min) — successful transfer moves
   money between two `Account`s in a `Ledger`; insufficient funds → failed
   result, *both* balances untouched; unknown `from` or `to` → failed result
   with `:account_not_found`, nothing touched.
4. **`Ledger`** (~20 min) — builds from an array of accounts, `#find` by
   number, unknown number returns `nil` (not an exception — a missing account
   is an expected case `Transfer` has to handle, not a program error).
5. **Loaders** (~30 min) — `AccountLoader`/`TransferLoader` turn a CSV path
   into domain objects. Test against small fixture CSVs, not the real ones,
   so the unit tests aren't coupled to the sample data.
6. **`BatchRunner` + `ConsoleReport` + `bin/run.rb`** (~30 min) — wire it all
   together. Integration spec runs the *actual* provided CSVs and asserts the
   final balances match the hand-computed expected values below. Add
   `transfers_with_failures.csv` as a second fixture so the failure paths are
   covered by something, since the provided sample data is all happy-path.
7. **README + polish** (~20–30 min) — how to install/run/test, assumptions
   made, questions sent to interviewer, and the expected-output table below for a
   reviewer to sanity-check against.

## Expected result for the provided sample data

Hand-verified so the integration test has a known-correct target (totals
$66,750.00 before and after — nothing created or destroyed):

| Account | Start | End |
|---|---:|---:|
| 1111234522226789 | 5000.00 | 4820.50 |
| 1111234522221234 | 10000.00 | 9974.40 |
| 2222123433331212 | 550.00 | 1550.00 |
| 1212343433335665 | 1200.00 | 1725.60 |
| 3212343433335755 | 50000.00 | 48679.50 |

All four sample transfers succeed — none of them trip the overdraft or
missing-account paths, so an extra fixture drives both branches directly
rather than leaving them implicitly untested.

## Principles applied

- **Domain models own their invariants and policy**, not the code around
  them — `Account` can't be debited below zero regardless of caller; `Transfer`
  decides the skip-and-report outcome, not `BatchRunner` or the loaders.
  Logic lives next to the data it protects.
- **Separation of concerns holds end-to-end** — parsing
  (`AccountLoader`/`TransferLoader`), business rules (`Transfer`),
  orchestration (`BatchRunner`), and formatting (`ConsoleReport`) are four
  classes that don't reach into each other. Each one is explainable in a
  sentence.
- **Native data structures, used for what they're actually good at** —
  `Hash` for the ledger (O(1) lookup by account number, the hot path during
  a transfer), `Array` for the ordered list of results. No unnecessary
  wrapping.
- **Short methods, one level of abstraction each**; guard clauses over
  nested conditionals.
- **Tests are isolated and read as documentation** — each spec exercises
  one class; `BatchRunner`'s integration spec is the only one touching the
  full stack, so a failure there points at wiring, not business logic.
- **Every failure path has a dedicated test, not just the happy path** —
  see the fixture note above.

## Stretch goals

Things I'd add if this were a real system, not a time-boxed exercise:

1. **Lock down which files it'll read.** `bin/run.rb` takes a file path
   straight from the command line right now, no allowlist or sandboxing. A
   real automated batch job shouldn't accept a free-text path from an
   untrusted source at all. Options, weakest to strongest:
   1. Resolve with `File.realpath` and check the resolved path against an
      allowed directory — still leaves a small window between resolving and
      opening.
   2. Open with the `File::NOFOLLOW` flag — the OS refuses the read outright
      if the path is a symlink, no race window at all.
   3. Don't accept a caller-supplied path in the first place — take an
      opaque upload ID, resolve it server-side. Eliminates the whole
      category instead of patching around it; the actual fix for a real
      system.
   4. Defense in depth: least-privilege file permissions, so even a
      successful traversal can't reach anything sensitive.
2. **Stream the CSV instead of loading it all at once.** `CSV.read` pulls
   the whole file into memory before processing a row. Fine for a day's
   transfers, not for a huge file — `CSV.foreach` would process one row at
   a time.
3. **A real logger instead of `warn`.** Warnings go to stderr as plain text.
   A proper logger (levels, parseable format) matters once this runs
   unattended as a daily job.
4. **An output format besides the console.** A CSV or JSON option would
   make it easier to feed downstream instead of a human reading it.
5. **Hard-stop on a totally unparseable accounts file, not just a bad row.**
   `AccountLoader.read_csv` currently rescues `CSV::MalformedCSVError` and
   returns `[]` — indistinguishable from a legitimately empty file. That
   flows through as an empty `Ledger`, so every transfer fails with
   `account_not_found`, and the report reads like every account is missing
   rather than "the file itself couldn't be read." Fix: have `read_csv`
   return `nil` on a parse failure instead of `[]`, `AccountLoader.load`
   propagate that `nil` instead of running `filter_map` on it, and
   `bin/run.rb` hard-stop on a `nil` result the same way it already does
   for a missing file.

## Open questions (sent, not blocking)

1. Preferred output format (console vs. CSV vs. both).
2. Anything else they'd flag about account-not-found handling, now that I've
   stated it as an assumption rather than asked outright.
