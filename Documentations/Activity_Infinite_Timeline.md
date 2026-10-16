# Activity timeline and compact Home/Profile

Activity keeps the existing financial classifications, details routes, failed-attempt presentation, date filters, category assignments, text search fields and 300 ms debounce. Its numbered footer is removed. The SQL-filtered total appears once beside **Filters**, with explicit counting, count-error and retry states. A changed query never displays the preceding query's count.

## Pagination and refresh

- The timeline requests **50 results per batch**, in descending `COALESCE(transaction_date, received_at), id` order. An exclusive timestamp/ID cursor replaces offsets on this path. A derived expression index is created idempotently when existing databases open; schema version remains **11**, and stored rows/assignments are unchanged.
- Approaching within 480 logical pixels of the end requests the next batch. Individual headers and transaction rows are built lazily; a large single day does not construct every transaction widget at once. Loaded batches merge into the existing date groups.
- One append can be in flight per timeline. Generation checks discard superseded refreshes and results belonging to disposed filters. IDs are deduplicated on publication. An exact multiple of 50 requires one final empty batch to establish the end.
- Database transaction changes, explicit refresh/resume and relevant category-assignment changes refresh the already-loaded depth atomically. They do not mix a new first batch with an old cursor tail. The existing Unicode-qualified identity/provider verification remains bounded in repository candidate batches; its financial matching policy is unchanged.
- Opening details keeps the timeline mounted, retaining its loaded records, query and scroll controller. Returning without edits makes no new timeline request. Appends show a small bottom spinner; failures retain existing rows and offer a bottom retry using the same cursor. Failed refreshes retry from the beginning of the loaded range.

## Amount search

Amount matching uses numeric SQL comparisons on the transaction's principal `amount`, combined with the existing literal text-field search **before** counting and pagination. It does not search balances/fees as amounts, parse every transaction in Flutter, or change stored financial values. The same numeric matcher is used during the repository's existing identity verification.

The whole-number portion is complete; omitted or partial decimal places express the amount prefix. This deliberately avoids arbitrary digit fragments: an amount query `500` does not match principal `1500` or `5000`. Text-field matches (such as an account/reference containing `500`) continue to work as before.

| Search | Principal amount match |
| --- | --- |
| `500` | `500.00` through `500.99` |
| `1,500`, `1500`, `KSh 1500` | `1500.00` through `1500.99` |
| `1500.0` | `1500.00` through `1500.09` |
| `1500.00`, `KSh 1,500.00` | Exactly `1500.00` |

Commas must use valid thousands grouping; malformed amount input retains only ordinary literal text searching. Zero remains a valid amount. Large numeric inputs remain bounded by finite database numeric representation rather than an arbitrary business limit.

## Home and Profile

Home's header has less vertical padding, and the sticky header/month section is 22 logical pixels shorter at ordinary text sizes. Existing wrapping, logo, white avatar and profile shortcut remain.

Profile's user surface is compact, with the device-lock icon after “Personal finances, on your device” and a smaller local-storage notice underneath. Finance shortcuts keep their grid; Settings uses full-width rows. **Export data** and **Contact us** open clearly labelled future-implementation pages and perform no export or external contact. Existing Appearance, app lock, Backup & restore and Help & about behaviors are preserved.

The avatar picker has 16 locally persisted choices, four per row. The original six persisted names and rocket default remain compatible. The ten additions are Bunny, Gamer, Reader, Explorer, Bird, Flower, Sun, Moon, Planet and Mountain. Category entry points use a consistent outlined tag icon. Activity scope labels and shared transaction metadata inherit their theme font family, including in rendered captures.

## Rendered captures

All figures use synthetic records.

- [Activity timeline and filtered count](v2-captures/activity/activity-timeline.png)
- [Amount search](v2-captures/activity/activity-amount-search.png)
- [Compact Home header](v2-captures/activity/home-compact-header.png)
- [Compact Profile with settings rows](v2-captures/activity/profile-compact.png)
- [Sixteen avatars in four columns](v2-captures/activity/avatars-four-columns.png)

## Validation

**164 focused tests pass** across repository filtering/cursors/amount matching, timeline concurrency and retries, Activity/search/category screens, detail and tab scroll restoration, Home, Profile/settings/avatars, navigation/keyboard insets and the synthetic v10-to-v11 preservation migration. Cases include batches crossing equal timestamps, inserting records between batches, SQL counts beyond the loaded range, rapid searches completing out of order, empty/error/count-error states and larger text. The full test suite was not run.

Scoped analysis of all 32 changed/new Dart files reports no issues. Formatter verification and `git diff --check` pass. Existing transaction data, schema version 11, category semantics, calculations, import and reconciliation logic are unchanged. These changes are prepared on the isolated task branch for review against `v2`.
