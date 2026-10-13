import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// One SQLite snapshot of persisted totals; no message bodies or history reads.
class YourDataSummary {
  final int successfulRecords;
  final int records,
      messages,
      categories,
      hiddenCategories,
      rules,
      activeInstruments,
      archivedInstruments,
      balances,
      manualBalances,
      smsBalances,
      unattributedSmsBalances;
  const YourDataSummary({
    required this.successfulRecords,
    required this.records,
    required this.messages,
    required this.categories,
    required this.hiddenCategories,
    required this.rules,
    required this.activeInstruments,
    required this.archivedInstruments,
    required this.balances,
    required this.manualBalances,
    required this.smsBalances,
    required this.unattributedSmsBalances,
  });
}

class YourDataRepository {
  final AppDatabase database;
  YourDataRepository(this.database);

  static const smsPageSize = 50;

  /// A bounded metadata-only view. Never selects bodies, senders or source IDs.
  Stream<List<DateTime>> watchSmsReceiptDates(int page) {
    if (page < 0) throw ArgumentError.value(page, 'page');
    final messages = database.rawMessages;
    final query = database.selectOnly(messages)
      ..addColumns([messages.receivedAt])
      ..orderBy([
        OrderingTerm.desc(messages.receivedAt),
        OrderingTerm.desc(messages.id),
      ])
      ..limit(smsPageSize, offset: page * smsPageSize);
    return query.watch().map(
      (rows) => rows.map((row) => row.read(messages.receivedAt)!).toList(),
    );
  }

  Stream<YourDataSummary> watchSummary() => database
      .customSelect(
        """SELECT
      (SELECT COUNT(*) FROM financial_records) AS records,
      (SELECT COUNT(*) FROM financial_records WHERE status = 'successful') AS successful_records,
      (SELECT COUNT(*) FROM raw_messages) AS messages,
      (SELECT COUNT(*) FROM transaction_categories) AS categories,
      (SELECT COUNT(*) FROM transaction_categories WHERE is_hidden = 1) AS hidden_categories,
      (SELECT COUNT(*) FROM category_rules) AS rules,
      (SELECT COUNT(*) FROM accounts WHERE is_user_registered = 1 AND is_active = 1) AS active_instruments,
      (SELECT COUNT(*) FROM accounts WHERE is_user_registered = 1 AND is_active = 0) AS archived_instruments,
      (SELECT COUNT(*) FROM balance_evidence) AS balances,
      (SELECT COUNT(*) FROM balance_evidence WHERE origin = 'manual') AS manual_balances,
      (SELECT COUNT(*) FROM balance_evidence WHERE origin = 'sms_reported') AS sms_balances,
      (SELECT COUNT(*) FROM balance_evidence WHERE origin = 'sms_reported' AND account_id IS NULL) AS unattributed_sms_balances
    """,
        readsFrom: {
          database.financialRecords,
          database.rawMessages,
          database.transactionCategories,
          database.categoryRules,
          database.accounts,
          database.balanceEvidence,
        },
      )
      .watchSingle()
      .map(
        (row) => YourDataSummary(
          successfulRecords: row.read<int>('successful_records'),
          records: row.read<int>('records'),
          messages: row.read<int>('messages'),
          categories: row.read<int>('categories'),
          hiddenCategories: row.read<int>('hidden_categories'),
          rules: row.read<int>('rules'),
          activeInstruments: row.read<int>('active_instruments'),
          archivedInstruments: row.read<int>('archived_instruments'),
          balances: row.read<int>('balances'),
          manualBalances: row.read<int>('manual_balances'),
          smsBalances: row.read<int>('sms_balances'),
          unattributedSmsBalances: row.read<int>('unattributed_sms_balances'),
        ),
      );
}
