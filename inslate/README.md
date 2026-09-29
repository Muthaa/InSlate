# InSlate

A Financial Insights Flutter project.

## Getting Started

                   PRESENTATION
---------------------------------------------------
Dashboard
Transactions
Accounts
Analytics
Investments
Budgets
Settings

                ▲
                │ Riverpod
                ▼

                 DOMAIN
---------------------------------------------------
FinancialRecord
Party
Category
Account
Budget
Investment

Repository Interfaces

                ▲
                │
                ▼

                 DATA
---------------------------------------------------
SmsTransactionSource
PdfTransactionSource
ExcelTransactionSource

Classifier
ParserFactory
Parsers

SQLite (Drift)

                ▲
                │
                ▼

              EXTERNAL
---------------------------------------------------
SMS
PDF
Excel
Cloud (future)
