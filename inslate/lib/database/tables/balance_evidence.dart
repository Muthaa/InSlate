import 'package:drift/drift.dart';
import 'accounts.dart';
import 'financial_records.dart';
import 'raw_messages.dart';

@DataClassName('StoredBalanceEvidence')
@TableIndex(
  name: 'balance_evidence_account_asof_idx',
  columns: {#accountId, #asOfMillis},
)
class BalanceEvidence extends Table {
  TextColumn get id => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get kind => text()();
  TextColumn get subjectFamily => text().nullable()();
  TextColumn get origin => text()();
  IntColumn get asOfMillis => integer()();
  TextColumn get timeBasis => text()();
  IntColumn get createdMillis => integer()();
  IntColumn get financialRecordId => integer().nullable().references(
    FinancialRecords,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get rawMessageId => integer().nullable().references(
    RawMessages,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get matchedClause => text().nullable()();
  TextColumn get extractionVersion => text().nullable()();
  IntColumn get accountId => integer().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get associationOrigin => text().nullable()();
  IntColumn get associatedMillis => integer().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}
