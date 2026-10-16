# Explicit instrument account-reference mappings

Schema v11 adds nullable interpreted_type, interpreted_subtype and interpretation_mapping_id columns to FinancialRecords and an instrument_mappings registry. Original parsed fields, amounts, fees, dates, source identities and numeric links remain intact during migration. Existing records receive no interpretation during migration.

From an active registered instrument's Details, choose **Map SMS account reference**. Select a detected reference or enter one, choose investment/savings/loan/unknown, preview actual matches, then confirm applying to matching history and future records. A zero-match mapping is valid for future imports.

Matching requires an exact provider key and customer account reference. Provider keys reuse the catalogue's exact published names/aliases and whitespace/case normalization. References reuse PartyIdentity's trim/lowercase account normalization; punctuation and internal characters are preserved. Provider names alone do not establish ownership. Reference uniqueness covers both directions; a shared reference cannot silently target two instruments or purposes.

Outgoing PayBills and existing savings/investment/loan deposits or repayments link the destination. Incoming receipts, withdrawals and disbursements link the source. Missing references, unsupported transaction shapes and conflicting existing links are skipped. Incoming M-PESA receipts often lack a customer account reference; they cannot be linked by guessing from the provider.

Confirmed investment purpose resolves purchase/redemption, savings resolves deposit/withdrawal, and loan resolves repayment/borrowing. Explicit parsed loan wording takes precedence. Reversed PayBill original/reversal pairs retain expense semantics; a newly validated reversal clears an original's interpretation while preserving links. Principal-only reversals and fees retain their existing policy.

New ordinary PayBills/receipts whose provider exactly matches the catalogue can be marked purpose-unspecified without any account association. Existing parsed investment/savings classifications remain intact. No substring/provider-only ownership inference or product-specific parsing is added. These unspecified movements appear in Activity and Detected providers, but are excluded from ordinary income/expense principal until a purpose is confirmed. Fees continue to count once. The unspecified-provider card supports registration and a provider/reference-qualified Activity drill-down restricted to unspecified payment subtypes.

Domain mapping and SQL predicates/aggregations both use COALESCE(interpreted_*, parsed_*). Dashboard, Insights, budgets, Activity counts/pagination and existing breakdowns therefore share the same interpretation. Registered savings uses a generic endpoint with the existing party identity, without pretending it is M-Shwari or KCB M-PESA. Categories remain stored; mapped non-expense/non-income movements no longer contribute to ordinary category totals. No independent category rules apply to those mapped movements.

Historical preview/application uses numeric-ID keyset batches of 100 and bounded reversal-protection reads. Confirmation is transactional. Future application runs inside the FinancialRecords repository save transaction before category rules, processing only newly persisted rows. SQL aggregation supplies detected references; reference selection pages contain at most 50 groups. No RawMessages are reimported and no balances are inferred.

Archiving retains interpretations and links in history and prevents future links to that instrument. Removing a mapping transactionally restores its records' parsed financial treatment and stops future matching, while retaining numeric links for explicit individual unlinking. Changing a mapping requires explicit removal and a new preview/confirmation. Existing link conflicts require individual review; they are never replaced silently.

Limits: no product-specific SMS parsing, inferred ownership, provider-only incoming linking, balances, historical catalogue-only reclassification, or ambiguous shared-reference splitting. Existing instrument identifier metadata alone does not activate matching; the explicit account-reference mapping confirmation is required. Unknown-purpose movements are not ordinary spending or income, and should not be presented as investment returns or valuations.

## Files changed for this implementation

- Persistence: `lib/database/app_database.dart`, generated `app_database.g.dart`, `tables/financial_records.dart`, and `daos/financial_records_dao.dart`.
- Domain and shared meaning: `lib/models/financial_records.dart`, `lib/core/enums/record_subtype.dart`, `lib/core/presentation/financial_presentation.dart`, `lib/services/financial_semantics.dart`, and `financial_breakdown_service.dart`.
- Repositories: new `instrument_mappings_repository.dart`; updated financial records, Insights, budgets, instrument links, PayBill reversals and detected providers repositories.
- Refresh: financial records and instrument history providers.
- Screens: new Instrument Mapping screen; Instrument Details, Financial Instruments, Detected Providers, transaction instruments section and Transaction Details.
- Tests: new mapping repository/widget/v10 migration tests; adjusted link endpoint tests, exhaustive semantics policy and legacy migration fixtures for the additive v11 columns/table.

## Validation

The final consolidated targeted run passed **226 tests**. It included all database tests; mapping, linking, reversal, Insights, budget, detection, Activity, category and import repositories/services; and the affected instrument, mapping, discovery, catalogue, Dashboard integration, Insights and budget screens. Flutter analyze passed with no issues. Formatting and git diff --check passed. The full suite and device database were not run or modified for this implementation.


## Approved v11 visibility and grouping fixes

Dashboard and Insights share a SQL-backed **Purpose unspecified** card. It sums principal and counts separately for effective `instrumentPayment` and `instrumentReceipt` within the selected half-open period, using `COALESCE(transaction_date, received_at)`. Fees are not included in these amounts. Canonical income, expenses, fees and net cash flow are unchanged. A recorded zero still has a transaction count; no matching rows show an explicit empty state. Each direction opens Activity with the same effective subtype and period.

Detected-provider aggregation now includes exact normalized provider key and customer reference in its grouping key. Provider names/aliases reuse the catalogue; customer references reuse the existing account identity normalization. A missing reference is not a wildcard: it retains a provider-qualified identity group and never establishes a confirmed account. Existing generic savings groups without a party retain their account-family grouping. Activity preserves the provider/reference constraint through search, period selection and clearing user filters. SQL applies effective subtype/family, dates and other existing filters; bounded 100-row candidate reads resolve exact Unicode-aware provider/reference identities before result pagination or counts. No per-record lookup or complete-history loading is added.

Reference mapping explicitly confirms purpose **per reference**, warns that shared references may represent several products and directs ambiguous/conflicting cases to individual review. Detected counts include unsupported transaction shapes and are now labelled separately from eligible previews. Confirmation and link-conflict safeguards are unchanged.

Changed implementation files:

- `lib/models/activity_filter.dart`
- `lib/database/daos/financial_records_dao.dart`
- `lib/repositories/financial_records_repository.dart`
- `lib/repositories/detected_providers_repository.dart`
- `lib/repositories/unspecified_movements_repository.dart` (new)
- `lib/widgets/unspecified_movements_card.dart` (new shared card/provider)
- `lib/screens/dashboard/dashboard_screen.dart`
- `lib/screens/insights/insights_screen.dart`
- `lib/screens/activity/activity_screen.dart`
- `lib/screens/instruments/detected_providers_screen.dart`
- `lib/screens/instruments/instrument_mapping_screen.dart`

Validation files:

- `test/repositories/instrument_visibility_test.dart` (new)
- `test/screens/unspecified_movements_card_test.dart` (new)
- `test/repositories/detected_providers_repository_test.dart`
- `test/repositories/instrument_mappings_repository_test.dart`
- `test/screens/detected_providers_screen_test.dart`
- `test/screens/instrument_mapping_screen_test.dart`
- `test/screens/activity_search_screen_test.dart` (current arrow controls/page labels)
- `test/database/device_v11_upgrade_test.dart` (new, opt-in private-copy verification)
- `tool/capture_v11_upgrade_backup.py` (new, read-only capture)

Validation: 144 tests passed in the consolidated targeted run, including private device-copy migration. A subsequent named/unnamed savings and cross-family grouping test passed, with all six affected grouping checks rerun successfully: 145 distinct tests passed. Analyzer reports no issues. No full suite was run.

Device preparation: the read-only v10 capture contains 8,833 financial records, 8,937 RawMessages, one registered account, 12 balance observations, one budget and 16 categories. The existing v10?v11 migration was verified against a separate private copy: every existing table/row and relationship is unchanged; only three nullable interpretation columns and an empty mapping table are introduced. No existing records become unspecified or acquire links during migration. The original v10 backup is retained outside the repository with its SHA-256 manifest. No device installation, launch, import or historical mapping was performed for these fixes. A debug APK is prepared for subsequent controlled live verification.

Limits remain: shared references cannot be split automatically; receipts without customer references cannot receive exact-reference mappings; registration/identifier metadata alone does not activate a mapping. SQL narrowing plus bounded shared normalization is intentionally retained instead of inventing different SQL identity rules. No category assignment/rule, financial semantics, schema or dependency changes were made in this fix.


## Phase 11U: discovery and registration UX

Financial Instruments is the central entry point: Registered (Active/Archived) and Accounts to review. Starting registration from a detected provider pre-fills its details, but saving still requires the user to confirm registration. Saving opens Instrument Details directly. Existing registrations at the provider can be opened from discovery, with a chooser for multiple products.

Instrument Details embeds account-reference setup alongside linked Activity and recorded balances. References are masked and show detected, eligible and conflicting transaction counts, plus awaiting-review/mapped-here/mapped-elsewhere status. Eligibility is evaluated using the existing mapping decision path, once per bounded reference page; there is no independent classification policy in the UI. Manual reference entry remains a secondary action.

Users choose Savings, Investment, Loan or Not sure for an exact provider/reference pair. A transaction preview includes persisted record links, amounts, dates and resulting treatment (or explicit conflict/protection status). Confirming reuses the existing transactional v11 workflow. Selecting the shared-product warning disables bulk confirmation and requires individual transaction review. Mapped references cannot be silently replaced. Removal still retains historical numeric links and restores parsed treatment as documented above.

Discovery groups providers in SQL-backed pages of 20 (one look-ahead provider), reference setup uses pages of 50, and historical preview uses pages of 20. Preview counts and rows are read in one transaction with the engine's existing 100-record keyset traversal; full message history is never loaded into Dart. The preview refreshes after returning from Transaction Details.

Accounts to review are setup tasks, not Purpose unspecified financial movements. Read-only discovery also exposes catalogue-recognized legacy payments/receipts and loan movements, using matching subtype/provider/reference Activity filters. This does not write interpretation fields, infer ownership, create financial records, or apply any historical classification. Financial interpretation, explicit loan precedence, reversal protection, categories, balances and schema v11 remain unchanged.

Remaining limits: reference-less incoming messages still require individual linking; a shared reference cannot be split automatically; a missing reference or uncatalogued provider cannot be invented. Users can enter exact references manually for future matching after confirmation. No live-device data changes or installation are part of this UX implementation.

Phase 11U validation: 56 tests passed across mapping repository, detected-provider repository, instrument visibility, mapping UI, detected-provider navigation, financial instrument CRUD UI, instrument history and balance UI. Flutter analyzer reports no issues; formatter and git diff --check pass. No full test suite or live-device operation was performed.
