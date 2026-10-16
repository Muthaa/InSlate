# Insights purpose-category donuts

Expense purpose categories and Income purpose categories each display a donut with the period total in its center and a matching category legend below. Headers retain their labels without duplicate totals. Legend entries retain exact amounts, transaction counts, one-decimal shares, hidden-category labels and the original filtered Activity destinations. Tapping a segment opens the same transactions as its legend entry; the center is not an action. Screen readers can use the labelled category actions without interpreting the chart colors.

The donut is drawn only when category amounts are nonnegative, the period total is positive, and category totals reconcile within floating-point tolerance. Zero and negative totals, negative category adjustments and inconsistent distributions use a neutral ring with an explicit explanation. Signed amounts stay visible in the legend and remain drillable. Negative values are never converted to absolute values, and positive categories are never plotted alone while silently dropping negative adjustments. Zero-valued categories remain in the legend without receiving artificial slices. No records produces the existing empty message rather than an invented distribution.

The chart uses Flutter CustomPainter without a new dependency or animation. The legend wraps for larger text; exact values remain available outside the fitted center label. Purpose unspecified stays last with its top gap. Financial calculations, schema and repository queries are unchanged.

## Rendered review captures

- [Expense donut with four synthetic categories](v2-captures/donuts/expense-donut.png)
- [Income donut with three synthetic categories](v2-captures/donuts/income-donut.png)
- [Insights screen](v2-captures/donuts/insights-categories.png)

17 focused donut and Insights widget tests pass, including segment hit testing, exact category filters, legend navigation, hidden/zero categories, negative adjustments, mismatched totals, empty states and narrow screens with doubled text. Analyzer, formatting and whitespace checks pass.

## Purpose-based color identity

Donut segments and legend icons now share a centralized `CategoryVisual` keyed by the permanent category ID, rather than the current list position. Period changes, spending-rank changes, renaming and hiding preserve the category's visual identity. Each built-in purpose has a distinct color within its income/expense group and a recognizable icon.

| Expense purpose | Color family | Income purpose | Color family |
| --- | --- | --- | --- |
| Food & groceries | Amber | Salary | Teal |
| Transport | Blue | Business income | Blue |
| Housing | Indigo | Freelance income | Violet |
| Bills & utilities | Cyan | Gifts & support | Gold |
| Health | Rose | Refunds | Green |
| Education | Violet | Other income | Slate |
| Shopping | Plum | | |
| Leisure | Burnt orange | | |
| Family & support | Green | | |
| Other expenses | Slate | | |

Uncategorized entries use neutral gray and a question-mark icon. Custom expense categories use stable warm hues; custom income categories use stable green/blue/violet hues, derived from their IDs with contrast adjustment. Category colors identify purpose rather than financial desirability; amount colors continue to express income/expense meaning. Labels, icons, amounts and percentages keep the chart usable without relying on color alone.

21 focused color/donut/Insights checks pass. They verify distinct built-in colors, graphic contrast, custom icon-surface contrast, unchanged identities after reordering/renaming/hiding, drill-downs and signed/zero-value handling. Analyzer, formatting and whitespace checks pass. Rendered captures above are refreshed with actual built-in category IDs and synthetic amounts.

## Unified Insights overview

The Overview now includes the subtitle “Compared with preceding period”, selected and comparison period labels, and the comparison record count. Each Income, Expenses, Fees and Net cash flow section shows its current total followed by the signed amount difference, percentage less/more, and an up/down arrow (or a horizontal unchanged indicator). The separate comparison card is removed. Income/expense drill-downs and the selected-period record count remain available.

The existing `InsightChange` calculation is unchanged. Missing records in either period make differences unavailable; zero/negative baselines keep the absolute difference while explaining why a percentage is unavailable. Direction describes arithmetic movement rather than financial desirability. Metric pairs stack on narrow screens or with enlarged text.

23 focused color/chart/Insights tests pass, covering the combined hierarchy, current totals, differences, direction icons, nonpositive baselines, missing comparison populations, exact period drill-downs and enlarged text. Scoped analyzer, formatting and whitespace checks pass.

- [Before: separate comparison card](v2-captures/donuts/insights-comparison.png)
- [After: combined overview and comparison](v2-captures/donuts/insights-overview-comparison.png)

Captures use synthetic records.


### Overview spacing and comparison colors

The comparison subtitle sits 2 logical pixels below the Overview title in the same header block, avoiding the extra gap caused by the info button's touch target. The footer now reads “financial records in selected period”. Percentage text and direction icons use the existing accessible semantic palette: green for higher income/net cash flow or lower expenses/fees, red for the reverse, and muted gray for unchanged or unavailable percentages. Signed amount differences remain neutral. Labels and arrows continue to communicate meaning without color alone; calculations are unchanged.

All 10 focused Insights screen tests pass, including normal/enlarged-text header spacing, favorable/unfavorable comparison colors and neutral nonpositive-baseline states. Scoped analyzer, formatting and whitespace checks pass. The combined-overview capture above is refreshed.
