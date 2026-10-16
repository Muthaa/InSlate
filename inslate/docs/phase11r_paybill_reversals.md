# Phase 11R — principal-only PayBill reversals

Approved policy: a verified return of an outgoing PayBill's full principal is a
separate negative expense adjustment on the SMS-declared reversal date. It is
not ordinary income. The original principal, date, fee and instrument links are
unchanged. No fee refund is inferred.

## Storage and matching

Drift v9 → v10 adds one nullable numeric `financial_records.reverses_record_id`
self-reference with restricted deletion. Existing rows receive NULL. A unique
partial index prevents multiple full adjustments for an original; another
prevents duplicate reversal references. Enum values `reversal` and
`payBillReversal` explicitly identify the movement. No other table changes.

The five audited SMS have one complete format: a distinct leading confirmation
reference, an explicit original reference, “has been successfully reversed”, a
declared date and AM/PM minute, an explicit amount credited to the M-PESA account,
and “New M-PESA account balance is Ksh…”. Whitespace/case of wording may vary;
references remain exact uppercase values. The anchored parser rejects extra or
ambiguous clauses, malformed grouping/decimals, invalid dates/times, zero
principal and future declared timestamps.

The repository requires exactly one successful outgoing expense/PayBill with
the exact original reference. Principal is compared in integer cents, without
a tolerance. The original must have a declared date strictly before the
reversal, and the reversal reference must be distinct and unused. Unsupported
or unmatched confirmations are retained without invented financial records.

Matching reads are batched. New imports resolve claims after normal movements
are saved, within the existing RawMessage transaction. This also handles a
reversal preceding its original in the same input batch. The bounded historical
action reviews at most six retained confirmations, requires the audited
population of exactly five, and processes their explicit source identities in
one all-supported transaction. It neither reimports financial history nor
updates originals. Reruns preserve records and evidence content/associations.

## Financial and category behavior

`FinancialSemantics.principalContribution` and its SQL counterpart supply the
negative principal. Dashboard breakdowns, Insights and exact-cent Budget queries
use that contract. Fees are still counted once. Same-month full reversals cancel
principal; cross-month reversals reduce the later month's expenses without
rewriting the original month. A refund-only month can have negative expenses.
Undefined shares for non-positive net totals are omitted/explained.

Purpose-category SQL joins/EXISTS predicates use the original numeric record ID
for adjustments. Consequently later manual assignments, manual Uncategorized,
hidden categories and custom-category deletion are inherited dynamically.
Independent category edits and rules are disallowed on reversals. Activity
includes both distinct records in the expense population; category counts and
pagination use the same predicate before paging. Detail views navigate both
ways and explain principal-only treatment and minute precision.

Reported wallet balances are separate, unattributed SMS evidence, with exact KES
cents, original RawMessage reference, matched clause, extraction version and
`sms_declared_minute` basis. Existing deterministic wallet IDs are reused with
insert-or-ignore; associations/content cannot be overwritten. The reversal
FinancialRecord's legacy balance field remains NULL. No ownership is inferred;
an explicitly selected instrument endpoint for returned funds is destination.

SMS times have minute precision. Stored timestamps denote the start of that
declared minute using the app's existing local M-PESA date convention; this is
documented in details and evidence provenance, not claimed as second precision.

## Validation checkpoint

- Full Flutter suite run once: **503 passed, 2 opt-in private device audits skipped**.
- Final focused run: **42 passed** (reversal repository/widgets and existing
  Insights/Profile screens).
- Private five-message host replay passed: 5 adjustments and 5 wallet observations,
  followed by 5 duplicate outcomes with no mutations. Combined principal effect:
  expenses −KES 1,963.00; net cash flow +KES 1,963.00; income/fees unchanged.
- Final targeted run: **82 passed** (reversal repository/widgets, Dashboard screens,
  integration and FinancialBreakdownService), following localized percentage-bar
  guards and eleven analyzer brace fixes. No second full-suite run.
- Flutter analyzer: **no issues**. Formatter: **45 files, 0 changes**. Tracked and
  untracked whitespace checks passed. Final debug APK built and installed with
  `adb install -r`.
- Device baseline: schema v9; 8,932 RawMessages; 8,823 FinancialRecords; 0 balance
  observations; exactly five retained confirmations.
- Installed v10 migration verified separately before processing: every old column,
  numeric ID, row and relationship in all eight tables preserved; record/SMS/evidence
  counts unchanged; integrity OK and no foreign-key errors.
- User performed the bounded action and its repeat on-device (ADB taps are blocked).
  Actual final counts: **8,932 RawMessages; 8,828 FinancialRecords; 5 balance observations**.
  All five sources have one linked principal adjustment and one unattributed wallet
  observation. No unrelated records, original fees/dates/links, categories,
  instruments, assignments, rules or budgets changed. Five adjustments were added,
  not five ordinary income transactions.
- Opt-in `test/services/device_reversal_audit_test.dart` passed against the private
  baseline and final device capture: **1 passed**, with exact new content matching
  the five-message replay, original-table preservation, canonical/SQL period
  reconciliation, integrity OK, no foreign-key errors and an idempotent host rerun
  (5 existing outcomes, 0 creations). Device counts after the user-confirmed repeat
  remain +5 records/+5 evidence, never +10. Accessibility inspection did not expose
  the transient completion summary; repeat UI counters are not independently claimed.
- Actual combined effect: **expense principal −KES 1,963.00; net cash flow
  +KES 1,963.00; ordinary income and recorded fees unchanged**. Each audited reversal
  falls in the same month as its original; synthetic tests cover cross-month cases.
  The delayed receipt case uses the declared minute, not the later receipt date.
- No reset, uninstall, source-message mutation, generalized financial reimport
  or unrelated backfill was performed. Private database captures were deleted
  after reconciliation; original SMS remain on the device.

## Files changed in this phase

All existing modified/untracked work is retained. Paths below are relative to
`inslate/`; regenerated database code includes earlier uncommitted schema work.

Production:

- `lib/core/enums/financial_record_type.dart`
- `lib/core/enums/record_subtype.dart`
- `lib/core/mappers/financial_record_type_mapper.dart`
- `lib/core/presentation/financial_presentation.dart`
- `lib/database/app_database.dart`, `lib/database/app_database.g.dart`
- `lib/database/tables/financial_records.dart`
- `lib/database/daos/financial_records_dao.dart`
- `lib/models/financial_records.dart`, `lib/models/balance_observation.dart`
- `lib/providers/category_provider.dart`
- `lib/repositories/financial_records_repository.dart`
- `lib/repositories/categories_repository.dart`
- `lib/repositories/insights_repository.dart`
- `lib/repositories/budgets_repository.dart`
- `lib/repositories/instrument_links_repository.dart`
- `lib/repositories/paybill_reversals_repository.dart`
- `lib/services/financial_semantics.dart`
- `lib/services/financial_breakdown_service.dart`
- `lib/services/financial_summary_service.dart`
- `lib/services/transaction_import_service.dart`
- `lib/services/paybill_reversal_parser.dart`
- `lib/screens/activity/transaction_detail_screen.dart`
- `lib/screens/insights/insights_screen.dart`
- `lib/screens/dashboard/dashboard_screen.dart`
- `lib/screens/dashboard/financial_breakdown_screen.dart`
- `lib/screens/profile/your_data_screen.dart`
- `lib/screens/profile/verified_reversals_section.dart`
- `lib/widgets/transaction_row.dart`

Tests and diagnostics:

- `test/repositories/paybill_reversals_test.dart`
- `test/screens/paybill_reversal_screen_test.dart`
- `test/services/device_reversal_audit_test.dart`
- `test/services/device_import_audit_test.dart`
- `test/services/financial_semantics_test.dart`
- `test/services/financial_summary_service_test.dart`
- `test/repositories/activity_repository_test.dart`
- `test/repositories/insights_repository_test.dart`
- `test/repositories/budgets_repository_test.dart`
- `test/repositories/instrument_history_test.dart`
- `test/repositories/instrument_links_repository_test.dart`
- `test/repositories/categories_repository_test.dart`
- `test/repositories/category_rules_test.dart`
- `test/database/budgets_migration_test.dart`
- `test/database/balance_evidence_migration_test.dart`
- `test/database/financial_instruments_migration_test.dart`
- `tool/capture_reversal_audit.py`
- `docs/phase11r_paybill_reversals.md`

## Limits

Incoming/debit reversals, non-PayBill reversals, partial reversals, fee refunds,
same-minute or unknown chronology, missing originals and other wording remain
unsupported. A missing original arriving in a later import batch does not
trigger automatic historical matching. The five-source historical action is a
deliberately bounded audit operation, not generalized transaction reimport.
The app retains its existing local-date convention; timezone reinterpretation
is outside this phase. No financial account discovery, valuation or balances
from transaction history were added.
