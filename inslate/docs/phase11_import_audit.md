# Phase 11 — SMS import reconciliation

Completed 9 October 2026. Existing working-tree changes were preserved. No new
schema migration, parser rule, financial classification or dependency was added.

## Observed evidence

The connected Android device contained **9,057 MPESA inbox SMS**, using the same
exact sender eligibility as `SmsTransactionSource`. Counts below come from the
captured data and live import audit, not an expected baseline.

| Validation population | Encountered | Imported | Skipped | Duplicate | Failed |
| --- | ---: | ---: | ---: | ---: | ---: |
| Fresh host replay of the real inbox | 9,057 | 8,823 | 109 | 125 | 0 |
| First controlled live-device reconciliation | 9,057 | 0 | 0 | 9,057 | 0 |
| Second controlled live-device reconciliation | 9,057 | 0 | 0 | 9,057 | 0 |

Every live run had exactly 9,057 audit entries, unique encounter indices covering
0–9,056, and mutually exclusive outcomes whose counts sum to 9,057. The on-device
Your Data summary matched the logs. Duplicates comprised 8,932 previously retained
source identities and 125 identical sender/body encounters. Existing exact-body
duplicate policy was preserved; duplicate encounters do not require another raw row.

The 109 fresh-replay skips comprised 64 recognized failed attempts and 45
unsupported/non-movement messages. All 109 retained their raw SMS. No failed
attempt or balance-only notification produced a FinancialRecord.

Final device storage: **8,932 RawMessages; 8,823 FinancialRecords; 0 balance
observations; 0 Accounts/instruments; 16 seeded categories; 0 rules, assignments
or budgets**. The fresh replay separately extracted 10,465 unattributed balance
observations; these are test-copy results, not device balances. Existing SMS were
not backfilled during migration or duplicate import.

The first read-only inspection preceded the installed app's independent catch-up
of three messages and saw 8,929 raw rows / 8,820 financial rows. All reconciliation
and preservation comparisons use the subsequent stable 8,932 / 8,823 snapshot.

## Verified correctness and fixes

- Each encountered SMS now has one indexed outcome and a traceable source ID and
  reason. Repeated source IDs no longer disappear from counts or parse twice.
- Duplicates are separate from intentionally skipped SMS. Contradictory content
  for an existing source ID fails explicitly without overwriting stored content.
- Exceptions during classification/parsing become auditable failures rather than
  aborting accounting for the remaining batch.
- Import uses 500-message transactions. Raw SMS, extracted evidence, movement
  records and existing category-rule application commit together. A storage error
  rolls back the batch and reports failures; a subsequent import can retry it.
- Overlapping calls on one importer serialize. Repository lookups and persistence
  remain batched. Audit logging flushes once per batch rather than per SMS.
- Your Data has a user-initiated reconciliation action, disabled while processing,
  with four-way outcome counts, reason counts and separate raw/evidence counts.
- New audit logs omit message bodies, parties and amounts. Source IDs remain local
  for traceability. Existing historical logs were not deleted or rewritten.

The device initially ran schema **v4**, despite the workspace's v9 checkpoint.
Read-only copies passed integrity checks; host migration preserved every original
account, raw-message and financial-record column and ID. After explicit approval,
the debug APK was installed with `adb install -r` and launched. Its existing v4 →
v9 migration preserved the same data on-device. Final integrity was `ok`, with no
foreign-key violations. No uninstall, reset or app-data clearing occurred.

Current parsers matched all comparable legacy records' amounts, fees, dates,
balances, type/subtype/status and party fields. There were no duplicated financial
source IDs and no repeated reference/subtype groups. There were 301 shared-reference
pairs across different subtypes: 297 Fuliza/movement pairs and four receive/send
pairs. They remain separate SMS-derived records under the existing source-ID policy.

For the latest recorded month (134 records), canonical FinancialSemantics totals,
Insights aggregation, Activity counts/50-record pagination and exact-minor-unit
Budget expense principal reconciled. Fees remained separate from expense principal.

## Device and capture checks

Read-only checks included ADB device/package/permission inspection, MPESA inbox
query, stable database hashes, integrity/foreign-key checks and source/reference
coverage. Private captures stayed in OS temporary directories and were removed
after validation; no SMS bodies, phone numbers or identifiers appear in this report.

ADB shell introduced CRLF into embedded SMS newlines, initially producing 97 false
content conflicts. Byte comparison verified the transport artifact. The capture
tool now uses `adb exec-out`, preserves provider bytes, rejects live database
journals and requires unchanged pre/post database hashes. App matching rules were
not relaxed to accommodate capture artifacts.

The device disallowed synthetic taps (`INJECT_EVENTS`). The user manually ran
More → Your Data → Reconcile SMS inbox twice; ADB verified both complete logs and
the displayed result. No security-setting change was required.

## Validation

- Initial focused batch: **133 passing tests** covering import, Profile/Your Data,
  parsers/classifiers, wallet/provider evidence, financial semantics and migrations.
- Full suite ran **once**: **471 passed, 2 failed, 1 opt-in test skipped**. The two
  failures were stale v4/v5 migration fixtures retaining the v9 Budgets table/indexes;
  one also still expected schema 8. Fixtures were corrected without changing the
  production migration or weakening preservation assertions.
- Final affected batch: **61 passing tests** (`transaction_import_service_test`,
  `profile_your_data_screen_test`, `categories_repository_test`, `category_rules_test`).
  This includes both repaired full-suite failures. The full suite was not rerun.
- Opt-in real-device host replay: **1 passing test**, exercising preservation,
  fresh import, repeats, field comparison and cross-feature semantic reconciliation.
- `flutter analyze --no-pub`: no issues. Dart formatting and tracked/untracked
  whitespace checks passed. Debug APK build succeeded.

Reproduce the private replay with `python tool/capture_import_audit.py`, then
`flutter test --no-pub --dart-define=PHASE11_DEVICE_AUDIT_DIR=<printed-directory>
test/services/device_import_audit_test.dart`. Delete the private capture afterward.
The test is skipped by default and never writes to the Android device.

## Remaining release limitations

All captured SMS have an accounted outcome, but accounting is not complete support
for every financial format. The 45 unsupported/non-movement messages include
**five reversal confirmations**, balance queries, KCB loan-request processing
notices, credit-limit/statement notices, cancellations, insufficient-funds/service
errors, and account/PIN administration. Reversals remain excluded; choosing how
they adjust original movements needs an explicit financial-semantics decision.
No reversal, credit limit or pending request was invented as ordinary income or expense.

Exact-body duplicate matching can suppress identical notifications received on
different dates; this existing storage contract was deliberately preserved.
Already retained raw SMS are not automatically reparsed after parser upgrades.
Failed batch writes are retryable; retained parser failures need explicit review.
Foreground serialization does not eliminate possible separate-isolate SQLite
contention, which is surfaced as a failed batch rather than silent loss.

The real device's new features had no pre-existing registered instruments, budgets
or category assignments. Their non-empty states are covered by automated tests,
not this device's populated configuration. SMS balance timestamps remain receipt
proxies, and no balance ownership or live valuation was inferred.

## Phase 11 files touched

- `lib/models/import_progress.dart`
- `lib/providers/import_provider.dart`
- `lib/services/transaction_import_service.dart`
- `lib/services/import_logger.dart`
- `lib/services/background_sms_handler.dart`
- `lib/screens/onboarding/setup_screen.dart`
- `lib/screens/profile/your_data_screen.dart`
- `test/services/transaction_import_service_test.dart`
- `test/services/device_import_audit_test.dart`
- `test/screens/profile_your_data_screen_test.dart`
- `test/repositories/categories_repository_test.dart`
- `test/repositories/category_rules_test.dart`
- `tool/capture_import_audit.py`
- `docs/phase11_import_audit.md`
