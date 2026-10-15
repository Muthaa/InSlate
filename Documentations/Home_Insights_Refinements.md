# Home, Insights and Your Data refinements

Home no longer displays Purpose unspecified. The section remains in Insights, and the underlying financial semantics, repositories and transaction data are unchanged.

Insights expense and income purpose categories now follow Home's compact category presentation: small labels and amounts, transaction counts, share bars and direct transaction drill-downs. Every category remains available, including hidden/uncategorized groups. Shares retain their previous precision and zero/negative-total explanations. Compact rows are preferable to a circular breakdown here because they keep exact amounts and drill-downs readable and can represent negative adjustments and unavailable shares explicitly.

Compared with preceding period now uses the Overview arrangement: Income/Expenses together, then Fees/Net cash flow separated by a divider. The comparison period and record count remain above the metrics. Every metric retains its directional icon, signed absolute difference, percentage wording and unavailable-baseline handling. Narrow screens or enlarged text use a single column.

Your Data's device banner has 12 fewer logical pixels of vertical padding. Balance observations places its title between the icon and arrow, removing the separate title line. A 16-pixel top gap separates the data grid from Verified PayBill reversals. Reversal/import sections and their behavior are otherwise unchanged.

## Review captures

- [Home](v2-captures/refinements/home.png)
- [Insights comparison](v2-captures/refinements/insights-comparison.png)
- [Insights category rows](v2-captures/refinements/insights-categories.png)
- [Your Data](v2-captures/refinements/your-data.png)

Captures use synthetic records and actual Flutter rendering. 53 focused Home, Insights and Your Data checks pass; final Insights/capture checks pass after alignment adjustments. Coverage includes retained comparison values and percentages, two-column/single-column behavior, hidden-category drill-downs, zero-total shares, compact card structure and reversal spacing. Analyzer, formatting and whitespace checks pass.

## Suggested future Profile settings

These are recommendations, not added menu destinations:

- **Appearance**: system/light/dark theme and display preferences.
- **Privacy & security**: hide amounts and optional device-authenticated app lock.
- **Backup & restore**: local export, backup and validated restore, consistent with the offline identity.
- **Help & about**: app version, financial definitions and troubleshooting.

Each should be introduced with working destinations and its own scoped implementation.
