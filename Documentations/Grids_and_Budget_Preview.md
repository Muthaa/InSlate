# Home budgets and compact data grids

Home's Monthly budgets card now shows all active budget targets in a horizontal scroller. Each target retains its original target, spending, percentage, progress and remaining/overspent values. The next target peeks into view, and card height follows its content rather than a fixed height. Paused targets remain excluded. Manage budgets, period restrictions and loading/error/empty behavior are unchanged.

Profile's four menu cards use the same navy surface as the user area, with readable white labels and mint, blue and yellow accents. The compact icon/title/arrow layout and existing destinations remain intact.

Your Data starts with **Balance observations**, the renamed SMS balance entry, linking to the existing wallet summaries and history. Financial records, Raw SMS messages, Categories & rules and Registered financial instruments appear below in a two-column grid. All five data cards use a light navy surface. The records and raw SMS destinations remain available; category/rule and instrument counts remain informational. The device-data description stays behind the information icon. Reversal and import-session sections retain their behavior.

Both grids use the shared `ResponsiveCardGrid`, which aligns card heights within each row and switches to one column below 340 available logical pixels or when 16-point text scales above 22 points. Cards grow with their content, keeping counts and descriptions readable.

## Review captures

- [Horizontal Home budgets](v2-captures/grids/home-budgets.png), with synthetic targets and progress
- [Profile light](v2-captures/grids/profile-light.png) and [dark](v2-captures/grids/profile-dark.png)
- [Your Data](v2-captures/refinements/your-data.png), with an empty test database and its built-in categories

78 focused Dashboard, budget, Profile, Your Data, AppShell and device-inset widget checks pass, including horizontal access beyond three budgets, unchanged overspending values, grid ordering, retained destinations and doubled text sizes. Analyzer and formatting checks pass. No database, financial calculation, categorization or mapping changes are included.
