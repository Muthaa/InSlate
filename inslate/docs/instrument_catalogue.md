# Instrument catalogue and registration status

The catalogue is registration/discovery metadata, not investment advice, ownership evidence, a parser, or a financial classifier. Existing classifier terms now live on catalogue entries; the classifier reads InstrumentCatalogue.investmentKeywords. The separate investment_keywords.dart was removed. Matching behavior and ingestion remain unchanged. New registration-only entries have no classifier terms. No historical records are reclassified.

## Coverage

Sixteen product groups map onto the eight stable InstrumentType values. Funds, special/multi-asset (including user-described high-yield) products, equity/ETF/brokerage and trading accounts, and government securities use investment_account. Pensions, SACCO memberships and insurance retain their distinct types. Self-custody crypto wallets use other; crypto exchange accounts use investment_account. No token quantities, balances, valuations, yields, coverage or net worth are calculated. Users can register any provider via the custom option.

Product selection prefills a descriptive editable name and existing type. It is not persisted as a new subtype. Identifiers remain optional descriptive references. Never collect seed phrases, private keys, passwords, PINs or authentication tokens.

## Payment evidence

Only explicitly sourced routes are retained in instrument_catalogue.dart. They are not payment instructions, not guaranteed SMS recipient aliases, and are not consumed by classification or automatic linking. Sources include:

- CIC product-specific routes: https://cic.co.ke/wp-content/uploads/2022/11/Mpesa-Payment-Process-2.pdf
- Jubilee MMF: https://jubileeinsurance.com/ke/asset-management-products/jubilee-money-market-fund-kes/
- Genghis MMF: https://genghis-capital.com/wp-content/uploads/2024/08/Genghis-Money-Market-Fund-Flyer-3_compressed.pdf
- Gencap pension: https://genghis-capital.com/wp-content/uploads/2023/08/Gencap-IPP-FAQs.pdf
- Etica: https://eticacap.com/
- NSSF: https://selfservice.nssf.or.ke/member-resources/
- Kenversity: https://kenversitysacco.co.ke/
- Co-op: https://www.co-opbank.co.ke/ways_to_bank/paybill-400200/
- Enwealth Faraja: https://enwealth.co.ke/insurance/wp-content/uploads/sites/4/Faraja-Benevolent-Fund-Sign-Up.pdf

Other product sources consulted:

- SIB special funds: https://sib.co.ke/the-mansa-x-story/
- CBK Treasury accounts: https://www.centralbank.go.ke/securities/treasury-bills/
- Binance M-PESA P2P: https://www.binance.com/en-NG/blog/all/6488719534128639956
- Kuza: https://kuzaasset.com/products
- Absa: https://www.absabank.co.ke/corporate-and-investment/absa-asset-management/
- KCB: https://investment.kcbgroup.com/wealth-management
- Ndovu: https://ndovu.co/ke
- Britam: https://ke.britam.com/images/FormsAndDownloads/Money-Market-Fund-Brochure.pdf
- ICEA LION: https://www.icealion.co.ke/money-market-fund
- Old Mutual: https://client.oldmutual.co.ke/
- Zimele: https://www.zimele.co.ke/savings/

Unverified recipient spellings and paybills remain absent. Bank collection routes can serve third parties. Crypto P2P counterparties do not identify a wallet. Treasury CSD accounts and security identifiers do not establish a universal M-PESA route. Before future SMS recognition, validate actual redacted successful confirmations and product context, including outgoing and incoming meanings.

## Registered indicator

The detected-provider screen compares registered instrument metadata by exact normalized provider name (case/whitespace only), explicit catalogue aliases, and existing instrument type. Unknown names retain exact comparison. It shows active registrations or archived registrations, leaves the provider visible, and permits additional registration. This is a metadata correspondence, not proof that any activity is linked or SMS-verified ownership. No identifiers or source/destination links are modified. Legacy rows are excluded by the existing registered-instruments stream. One shared stream avoids per-card database queries.

No migration or new dependency.
