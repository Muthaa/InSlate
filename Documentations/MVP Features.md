MVP Features
Epic 1 — SMS Engine

This is Sprint 1.

Features
Request SMS permission
Read inbox
Filter Safaricom messages
Detect M-Pesa messages
Ignore everything else

Example

Inbox

✓ M-Pesa
✓ M-Pesa
✗ OTP
✗ WhatsApp
✗ Bank Promotion
✓ M-Pesa

Output

Found 1,283 M-Pesa messages
Epic 2 — Parser Engine

The parser becomes your biggest asset.

It converts

Confirmed.

KES 450.00 sent to John Doe on...

into

{
    "type":"send_money",
    "amount":450,
    "recipient":"John Doe",
    "date":"2026-06-30",
    "balance":5210,
    "transactionId":"THF73..."
}

Every message becomes JSON.

Epic 3 — Normalizer

Different messages represent different financial events.

Examples

Send Money

Sent to...

Receive Money

received KES...

Paybill

paid to...

Buy Goods

paid to Till...

Withdraw

withdrawn...

Deposit

deposited...

Fuliza

Fuliza...

Airtime

bought airtime...

Loan

M-Shwari...

Reverse

reversed...

Every one becomes a standard transaction object.

Epic 4 — Local Database

No backend.

SQLite only.

Tables

Transactions

Categories

Merchants

Accounts

Settings

Everything works offline.

Epic 5 — Dashboard

Keep it simple.

Spent Today

Spent This Week

Spent This Month

Current M-Pesa Balance

Transaction Count

No fancy charts yet.

Epic 6 — Categories

Initially rule-based.

Java
↓

Food
Uber
↓

Transport
Naivas
↓

Groceries

Later users can override.

Architecture

Transaction Source
        │
        ▼
Raw Message
        │
        ▼
Parser
        │
        ▼
Financial Event
        │
        ▼
Normalizer
        │
        ▼
Transaction Repository

I wouldn't even build authentication.

Flutter

│

├── SMS Layer

├── Parser Layer

├── Repository Layer

├── SQLite

├── Analytics Layer

└── UI

No internet.

Folder Structure
lib/

core/

features/

    sms/

    parser/

    transactions/

    dashboard/

    analytics/

    settings/

database/

services/

widgets/

Very feature-first.

State Management

I'd choose

Riverpod

Why?

Compile-time safety
Excellent testing
Scales well
Less boilerplate than BLoC
Database

Drift

instead of raw SQLite.

Why?

Type-safe
Reactive queries
Migrations
Better developer experience
SMS Parsing Strategy

This is the heart.

Don't parse inside widgets.

Create

SMS Reader

↓

Raw SMS

↓

Parser

↓

Normalizer

↓

Validator

↓

Transaction Model

↓

Database

Each stage should be independently testable.

Example

Raw SMS

Confirmed.

KES 350.00 sent to Mary Wanjiku
on 30/6/26 at 2:31 PM.

Balance is KES 2,430.00

↓

Parser

amount = 350

recipient = Mary Wanjiku

balance = 2430

date = ...

type = SEND_MONEY

↓

Database

Transaction(
 amount:350,
 type:SEND,
 merchant:null,
 category:Transfer
)
The Parser Is the Product

I would spend almost half the MVP here.

Create one parser per message type.

SendMoneyParser

PaybillParser

BuyGoodsParser

WithdrawParser

DepositParser

ReceiveMoneyParser

ReversalParser

FulizaParser

MShwariParser

Much cleaner than one huge regex.

Testing

Every parser gets sample messages.

Example

test/

send_money_test.dart

paybill_test.dart

withdraw_test.dart

buygoods_test.dart

Hundreds of SMS samples.

Eventually

Parser Accuracy

99.4%
Roadmap
Sprint 1

Read SMS

Sprint 2

Parse messages

Sprint 3

Save transactions

Sprint 4

Dashboard

Sprint 5

Categories

Sprint 6

Analytics

One architectural decision I would make from day one

Design the app around an abstraction called TransactionSource, not around SMS.

For example:

abstract class TransactionSource {
  Future<List<RawTransaction>> import();
}

Then implement:

MpesaSmsSource
MpesaStatementSource
BankStatementSource
ManualEntrySource
EmailStatementSource (future)
OpenBankingSource (future)

| Layer                | Choice                 |
| -------------------- | ---------------------- |
| Framework            | Flutter                |
| State Management     | Riverpod               |
| Routing              | GoRouter               |
| Local DB             | Drift                  |
| SMS                  | another_telephony      |
| Dependency Injection | Riverpod Providers     |
| JSON                 | json_serializable      |
| Logging              | logger                 |
| Charts               | fl_chart               |
| Storage              | flutter_secure_storage |
| Date Handling        | intl                   |
| UUID                 | uuid                   |
