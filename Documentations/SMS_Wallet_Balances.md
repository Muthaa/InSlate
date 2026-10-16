# SMS wallet balance cards

The SMS balance observations screen now shows one payment-style card for each observed wallet or product and currency. Incoming balance observations update that card instead of creating another wallet card. The layout uses a blue-to-navy gradient surface with yellow/blue accents and high-contrast light text, exact recorded amounts, observation timestamps and a History action. Cards expand for larger text; the page and its controls scroll together.

## Recorded financial meaning

- The latest observation is selected by its existing as-of time, then creation time and ID for deterministic ties. A late-arriving old SMS cannot replace a newer observation.
- Each SMS subject and currency remains separate. M-PESA, M-Shwari savings, KCB M-PESA savings, M-Shwari loan and Fuliza debt are distinct concepts. Available/reported balance labels follow the selected observation; they do not create duplicate product cards. No balances are summed, inferred or presented as live.
- M-PESA is the measured wallet. Its card/history has no association controls, it is excluded from **Needs association**, and the repository rejects new instrument associations for that subject. Existing source observations and any historical links remain intact.
- M-Shwari and KCB M-PESA retain explicit association of individual observations, including the existing compatibility checks, replacement confirmation and unlink flow. Association state is labelled **Latest observation**. A link on an older observation is not silently applied to new SMS.
- History is filtered to the card's subject/currency, retains original provenance and supports 20-observation pagination. SMS evidence is not edited or deleted by this redesign.

The summary query groups/counts in SQLite, then reads only the newest row for each distinct subject/currency. It does not download the complete observation history into the UI or group only the first page. Existing change streams refresh balances and association labels automatically.

No schema migration, transaction calculation, SMS permission or account-management repository changes are included. Historical extraction remains available and uses its existing implementation.

## Review and validation

[Light capture](v2-captures/wallets/wallets-light.png) · [Dark capture](v2-captures/wallets/wallets-dark.png)

Captures use synthetic SMS and actual Flutter widget rendering with Roboto and Material icon fonts.

81 focused tests pass across wallet summaries, SMS associations, historical extraction, balance evidence, schema migration, instrument balance screens and Your Data. Coverage includes more than one history page becoming one card, late older SMS, live updates, zero balances, separate products/currencies/debt, real M-Shwari and KCB association through the overview, scoped history, storage errors, empty/loading states and narrow screens with doubled text in both themes. Application code and changed/new tests analyze cleanly; changed Dart files pass formatting and whitespace checks. Physical Android testing and the full suite were not run.
