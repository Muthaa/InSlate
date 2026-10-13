import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../core/enums/record_subtype.dart';
import '../models/budget.dart';
import '../models/financial_period.dart';
import '../services/financial_semantics.dart';

class BudgetsRepository {
  final AppDatabase database;
  BudgetsRepository(this.database);

  Future<StoredBudget> _get(String id) =>
      (database.select(database.budgets)..where((b) => b.id.equals(id)))
          .getSingleOrNull()
          .then((b) => b ?? (throw ArgumentError('Budget no longer exists.')));
  Future<void> _category(String? id) async {
    if (id == null) return;
    final c = await (database.select(
      database.transactionCategories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (c == null || c.kind != 'expense') {
      throw ArgumentError('Choose an existing expense category.');
    }
  }

  Future<void> _unique(String? categoryId, {String? except}) async {
    final duplicate =
        await (database.select(database.budgets)..where(
              (b) =>
                  b.isActive.equals(true) &
                  (categoryId == null
                      ? b.scope.equals('overall')
                      : b.scope.equals('category') &
                            b.categoryId.equals(categoryId)) &
                  (except == null
                      ? const Constant(true)
                      : b.id.equals(except).not()),
            ))
            .getSingleOrNull();
    if (duplicate != null) {
      throw ArgumentError('An active budget already exists for this scope.');
    }
  }

  Future<String> create({required String amount, String? categoryId}) =>
      database.transaction(() async {
        final minor = parseBudgetMoney(amount);
        await _category(categoryId);
        await _unique(categoryId);
        final id = const Uuid().v4();
        await database
            .into(database.budgets)
            .insert(
              BudgetsCompanion.insert(
                id: id,
                scope: categoryId == null ? 'overall' : 'category',
                categoryId: Value(categoryId),
                amountMinor: minor,
              ),
            );
        return id;
      });
  Future<void> update({
    required String id,
    required String amount,
    String? categoryId,
  }) => database.transaction(() async {
    final old = await _get(id);
    final minor = parseBudgetMoney(amount);
    await _category(categoryId);
    final active =
        old.isActive && (old.scope == 'overall' || old.categoryId != null);
    if (active) await _unique(categoryId, except: id);
    await (database.update(
      database.budgets,
    )..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(
        scope: Value(categoryId == null ? 'overall' : 'category'),
        categoryId: Value(categoryId),
        amountMinor: Value(minor),
        isActive: Value(active),
      ),
    );
  });
  Future<void> setActive(String id, bool active) => database.transaction(
    () async {
      final b = await _get(id);
      if (active) {
        if (b.scope == 'category' && b.categoryId == null) {
          throw ArgumentError('Choose a replacement category before resuming.');
        }
        await _category(b.categoryId);
        await _unique(b.categoryId, except: id);
      }
      await (database.update(database.budgets)..where((b) => b.id.equals(id)))
          .write(BudgetsCompanion(isActive: Value(active)));
    },
  );
  Future<void> delete(String id) => database.transaction(() async {
    await _get(id);
    await (database.delete(
      database.budgets,
    )..where((b) => b.id.equals(id))).go();
  });

  /// Decimal TEXT -> INTEGER cents. No REAL multiplication or SUM of money.
  /// Unsupported sub-cent/scientific/very large legacy values invalidate the
  /// affected scope instead of silently rounding it. A REAL round-trip equality
  /// check detects digits lost by SQLite TEXT formatting; the 12-digit whole
  /// limit keeps each cent uniquely representable in the legacy REAL field. SUM overflow is surfaced
  /// as an unavailable query, never a fabricated spent value.
  Stream<List<BudgetProgress>> watch(FinancialPeriod period) {
    if (period != FinancialPeriod.month(period.start)) {
      throw ArgumentError('Choose a calendar month.');
    }
    final expense = RecordSubtype.values
        .where(
          (s) =>
              FinancialSemantics.forSubtype(s).movement ==
              MovementClass.expense,
        )
        .map(
          (s) =>
              "(${FinancialSemantics.effectiveSubtypeSql('f')} = '${s.name}' AND ${FinancialSemantics.effectiveTypeSql('f')} = '${FinancialSemantics.forSubtype(s).expectedType!.name}')",
        )
        .join(' OR ');
    return database
        .customSelect(
          """
      WITH expenses AS (
        SELECT a.category_id, ${FinancialSemantics.principalSql('f')} AS original_value, CAST((${FinancialSemantics.principalSql('f')}) AS TEXT) AS value
        FROM financial_records f LEFT JOIN record_category_assignments a ON a.financial_record_id = ${FinancialSemantics.categoryRecordSql('f')}
        WHERE ($expense) AND COALESCE(f.transaction_date, f.received_at) >= ?
          AND COALESCE(f.transaction_date, f.received_at) < ?
      ), unsigned AS (
        SELECT category_id, original_value, CASE WHEN substr(value, 1, 1) = '-' THEN -1 ELSE 1 END AS sign,
          CASE WHEN substr(value, 1, 1) = '-' THEN substr(value, 2) ELSE value END AS digits FROM expenses
      ), parts AS (
        SELECT *, CASE WHEN instr(digits, '.') = 0 THEN digits ELSE substr(digits, 1, instr(digits, '.') - 1) END AS whole,
          CASE WHEN instr(digits, '.') = 0 THEN '' ELSE substr(digits, instr(digits, '.') + 1) END AS fraction FROM unsigned
      ), cents AS (
        SELECT category_id,
          CASE WHEN digits != '' AND digits NOT GLOB '*[^0-9.]*' AND whole != ''
            AND length(whole) <= 12 AND instr(fraction, '.') = 0 AND substr(fraction, 3) NOT GLOB '*[1-9]*'
            AND original_value = CAST((CASE WHEN sign < 0 THEN '-' ELSE '' END) || whole || '.' || substr(fraction || '00', 1, 2) AS REAL)
            THEN sign * (CAST(whole AS INTEGER) * 100 + CAST(substr(fraction || '00', 1, 2) AS INTEGER)) ELSE NULL END AS minor FROM parts
      ), grouped AS (
        SELECT category_id, SUM(COALESCE(minor, 0)) AS spent, COUNT(*) AS count,
          SUM(CASE WHEN minor IS NULL THEN 1 ELSE 0 END) AS invalid FROM cents GROUP BY category_id
      ), overall AS (
        SELECT COALESCE(SUM(spent), 0) AS spent, COALESCE(SUM(count), 0) AS count,
          COALESCE(SUM(invalid), 0) AS invalid FROM grouped
      )
      SELECT b.*, c.display_name, COALESCE(c.is_hidden, 0) AS hidden,
        CASE WHEN b.scope = 'overall' THEN o.spent ELSE COALESCE(g.spent, 0) END AS spent,
        CASE WHEN b.scope = 'overall' THEN o.count ELSE COALESCE(g.count, 0) END AS count,
        CASE WHEN b.scope = 'overall' THEN o.invalid ELSE COALESCE(g.invalid, 0) END AS invalid
      FROM budgets b LEFT JOIN transaction_categories c ON c.id = b.category_id
      LEFT JOIN grouped g ON g.category_id = b.category_id CROSS JOIN overall o
      ORDER BY b.scope DESC, c.display_name, b.id
    """,
          variables: [
            Variable<int>(period.start.millisecondsSinceEpoch ~/ 1000),
            Variable<int>(period.end.millisecondsSinceEpoch ~/ 1000),
          ],
          readsFrom: {
            database.budgets,
            database.financialRecords,
            database.recordCategoryAssignments,
            database.transactionCategories,
          },
        )
        .watch()
        .map(
          (rows) => rows.map((r) {
            final overall = r.read<String>('scope') == 'overall';
            final categoryId = r.readNullable<String>('category_id');
            final budget = Budget(
              id: r.read<String>('id'),
              categoryId: categoryId,
              label: overall
                  ? 'Overall expenses'
                  : r.readNullable<String>('display_name') ??
                        'Deleted category',
              amountMinor: r.read<int>('amount_minor'),
              overall: overall,
              isActive:
                  r.read<bool>('is_active') && (overall || categoryId != null),
              categoryHidden: r.read<int>('hidden') == 1,
            );
            return BudgetProgress(
              budget,
              period,
              !budget.available || r.read<int>('invalid') > 0
                  ? null
                  : BigInt.from(r.read<int>('spent')),
              r.read<int>('count'),
            );
          }).toList(),
        );
  }
}
