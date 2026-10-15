# Insights purpose-category donuts

Expense purpose categories and Income purpose categories each display a donut with the period total in its center and a matching category legend below. Headers retain their labels without duplicate totals. Legend entries retain exact amounts, transaction counts, one-decimal shares, hidden-category labels and the original filtered Activity destinations. Tapping a segment opens the same transactions as its legend entry; the center is not an action. Screen readers can use the labelled category actions without interpreting the chart colors.

The donut is drawn only when category amounts are nonnegative, the period total is positive, and category totals reconcile within floating-point tolerance. Zero and negative totals, negative category adjustments and inconsistent distributions use a neutral ring with an explicit explanation. Signed amounts stay visible in the legend and remain drillable. Negative values are never converted to absolute values, and positive categories are never plotted alone while silently dropping negative adjustments. Zero-valued categories remain in the legend without receiving artificial slices. No records produces the existing empty message rather than an invented distribution.

The chart uses Flutter CustomPainter without a new dependency or animation. The legend wraps for larger text; exact values remain available outside the fitted center label. Purpose unspecified stays last with its top gap. Financial calculations, schema and repository queries are unchanged.

## Rendered review captures

- [Expense donut with four synthetic categories](v2-captures/donuts/expense-donut.png)
- [Income donut with three synthetic categories](v2-captures/donuts/income-donut.png)
- [Insights screen](v2-captures/donuts/insights-categories.png)

17 focused donut and Insights widget tests pass, including segment hit testing, exact category filters, legend navigation, hidden/zero categories, negative adjustments, mismatched totals, empty states and narrow screens with doubled text. Analyzer, formatting and whitespace checks pass.
