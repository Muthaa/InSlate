import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../models/financial_records.dart' as domain;
import '../database/app_database.dart';
import '../models/transaction_category.dart';
import '../services/financial_semantics.dart';
import 'financial_records_repository.dart';

/// Categories describe purpose only. They never update transaction fields.
class CategoriesRepository {
  final AppDatabase database;
  CategoriesRepository(this.database);

  Future<void> seedBuiltIns() => database.categoriesDao.seedBuiltIns();

  Stream<List<TransactionCategory>> watchCategories() => database
      .select(database.transactionCategories)
      .watch()
      .map(
        (rows) =>
            rows.map(_category).toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );

  Stream<CategoryAssignment?> watchAssignment(int recordId) =>
      (database.select(database.recordCategoryAssignments)
            ..where((row) => row.financialRecordId.equals(recordId)))
          .watchSingleOrNull()
          .map(
            (row) => row == null
                ? null
                : CategoryAssignment(
                    financialRecordId: row.financialRecordId,
                    categoryId: row.categoryId,
                    origin: CategoryAssignmentOrigin.values.byName(row.origin),
                    assignedAt: row.assignedAt,
                    ruleId: row.ruleId,
                  ),
          );

  Future<List<TransactionCategory>> getCategories({
    CategoryKind? kind,
    bool includeHidden = false,
  }) async {
    final rows = await database.categoriesDao.getCategories();
    return rows
        .where(
          (row) =>
              (kind == null || row.kind == kind.name) &&
              (includeHidden || !row.isHidden),
        )
        .map(_category)
        .toList();
  }

  Future<TransactionCategory?> getCategory(String id) async {
    final row = await database.categoriesDao.getCategory(id);
    return row == null ? null : _category(row);
  }

  Future<TransactionCategory> createCustom({
    required String name,
    required CategoryKind kind,
  }) async {
    final category = TransactionCategory(
      id: 'custom.${const Uuid().v4()}',
      name: _name(name),
      kind: kind,
    );
    await database
        .into(database.transactionCategories)
        .insert(
          TransactionCategoriesCompanion.insert(
            id: category.id,
            displayName: category.name,
            kind: category.kind.name,
          ),
        );
    return category;
  }

  Future<void> rename(String id, String name) async {
    final value = _name(name);
    final changed =
        await (database.update(database.transactionCategories)
              ..where((row) => row.id.equals(id)))
            .write(TransactionCategoriesCompanion(displayName: Value(value)));
    if (changed == 0) throw ArgumentError('Category does not exist');
  }

  Future<void> setHidden(String id, bool hidden) async {
    final changed =
        await (database.update(database.transactionCategories)
              ..where((row) => row.id.equals(id)))
            .write(TransactionCategoriesCompanion(isHidden: Value(hidden)));
    if (changed == 0) throw ArgumentError('Category does not exist');
  }

  /// Deleting a custom category clears its assignments, never its transactions.
  /// Built-ins are hidden rather than deleted so their identity stays stable.
  Future<void> deleteCustom(String id) => database.transaction(() async {
    final category = await getCategory(id);
    if (category == null) throw ArgumentError('Category does not exist');
    if (category.isBuiltIn) {
      throw ArgumentError('Built-in categories cannot be deleted');
    }
    await (database.delete(
      database.transactionCategories,
    )..where((row) => row.id.equals(id))).go();
  });

  Future<CategoryAssignment?> getAssignment(int recordId) async {
    final row = await database.categoriesDao.getAssignment(recordId);
    return row == null
        ? null
        : CategoryAssignment(
            financialRecordId: row.financialRecordId,
            categoryId: row.categoryId,
            origin: CategoryAssignmentOrigin.values.byName(row.origin),
            assignedAt: row.assignedAt,
            ruleId: row.ruleId,
          );
  }

  /// Replaces the one assignment atomically; no rule engine or detection runs.
  Future<void> assign({
    required int recordId,
    required String categoryId,
    CategoryAssignmentOrigin origin = CategoryAssignmentOrigin.manual,
  }) => database.transaction(() async {
    if (origin == CategoryAssignmentOrigin.manualUncategorized) {
      throw ArgumentError('Use removeAssignment to clear a category');
    }
    final category = await getCategory(categoryId);
    if (category == null || category.isHidden) {
      throw ArgumentError('Category is unavailable');
    }
    final record = await FinancialRecordsRepository(database).getById(recordId);
    if (record == null) throw ArgumentError('Financial record does not exist');
    if (FinancialSemantics.isExpenseReversal(record)) {
      throw ArgumentError(
        'Change the original transaction category; reversals inherit it.',
      );
    }
    final movement = const FinancialSemantics().classify(record);
    final eligible = category.kind == CategoryKind.income
        ? movement == MovementClass.income
        : movement == MovementClass.expense;
    if (!eligible) {
      throw ArgumentError(
        'Category kind does not match resolved financial meaning',
      );
    }
    final existing = await getAssignment(recordId);
    if (origin == CategoryAssignmentOrigin.ruleDerived &&
        existing != null &&
        existing.origin != CategoryAssignmentOrigin.ruleDerived) {
      return;
    }
    await database
        .into(database.recordCategoryAssignments)
        .insertOnConflictUpdate(
          RecordCategoryAssignmentsCompanion.insert(
            financialRecordId: recordId,
            categoryId: Value(categoryId),
            origin: origin.name,
            ruleId: const Value(null),
            assignedAt: Value(DateTime.now()),
          ),
        );
  });

  /// A user's clear is an explicit override, including against future rules.
  Future<void> removeAssignment(int recordId) => database.transaction(() async {
    final record = await FinancialRecordsRepository(database).getById(recordId);
    if (record == null || FinancialSemantics.isExpenseReversal(record)) {
      throw ArgumentError('Change the original transaction category.');
    }
    await database
        .into(database.recordCategoryAssignments)
        .insertOnConflictUpdate(
          RecordCategoryAssignmentsCompanion.insert(
            financialRecordId: recordId,
            categoryId: const Value(null),
            ruleId: const Value(null),
            origin: CategoryAssignmentOrigin.manualUncategorized.name,
            assignedAt: Value(DateTime.now()),
          ),
        );
  });

  /// Names alone are deliberately not sufficient for automatic categorization.
  static String? ruleIdentity(domain.FinancialRecord record) {
    final party = record.party;
    if (party == null) return null;
    final identity = PartyIdentity.fromParty(party);
    if (identity.kind == PartyIdentityKind.name || identity.value.isEmpty) {
      return null;
    }
    return jsonEncode([identity.kind.name, identity.value]);
  }

  static CategoryKind? _kind(domain.FinancialRecord record) =>
      FinancialSemantics.isExpenseReversal(record)
      ? null
      : switch (const FinancialSemantics().classify(record)) {
          MovementClass.income => CategoryKind.income,
          MovementClass.expense => CategoryKind.expense,
          _ => null,
        };

  Stream<List<StoredCategoryRule>> watchRules() => (database.select(
    database.categoryRules,
  )..orderBy([(r) => OrderingTerm.asc(r.id)])).watch();

  /// Stops future matching; keeps existing assignments and their origin.
  Future<void> deleteRule(int id) => (database.delete(
    database.categoryRules,
  )..where((r) => r.id.equals(id))).go();

  Future<void> assignSimilar({
    required int recordId,
    required String categoryId,
  }) => database.transaction(() async {
    final record = await FinancialRecordsRepository(database).getById(recordId);
    final key = record == null ? null : ruleIdentity(record);
    if (key == null) throw ArgumentError('Reliable party identity is required');
    await assign(recordId: recordId, categoryId: categoryId);
    await database
        .into(database.categoryRules)
        .insert(
          CategoryRulesCompanion.insert(
            identityKey: key,
            kind: _kind(record!)!.name,
            categoryId: categoryId,
          ),
          onConflict: DoUpdate(
            (_) => CategoryRulesCompanion(categoryId: Value(categoryId)),
            target: [
              database.categoryRules.identityKey,
              database.categoryRules.kind,
            ],
          ),
        );
    await applyRules();
  });

  /// Keyset pages bound memory. Rules/categories are fetched once and assignments
  /// once per page; no record-by-record queries or history-sized collections.
  Future<void> applyRules({int afterId = 0, int? throughId}) async {
    final rules = await database.select(database.categoryRules).get();
    if (rules.isEmpty) return;
    final categories = {
      for (final c in await database.categoriesDao.getCategories()) c.id: c,
    };
    final active = {
      for (final r in rules)
        if (categories[r.categoryId]?.isHidden == false &&
            categories[r.categoryId]?.kind == r.kind)
          (r.identityKey, r.kind): r,
    };
    if (active.isEmpty) return;
    final upper =
        throughId ??
        (await (database.select(database.financialRecords)
                  ..orderBy([(r) => OrderingTerm.desc(r.id)])
                  ..limit(1))
                .getSingleOrNull())
            ?.id ??
        0;
    var cursor = afterId;
    final repository = FinancialRecordsRepository(database);
    while (cursor < upper) {
      final rows =
          await (database.select(database.financialRecords)
                ..where(
                  (r) =>
                      r.id.isBiggerThanValue(cursor) &
                      r.id.isSmallerOrEqualValue(upper) &
                      r.partyName.isNotNull() &
                      (r.partyIdentifier.isNotNull() |
                          r.partyPhone.isNotNull() |
                          r.partyAccount.isNotNull()),
                )
                ..orderBy([(r) => OrderingTerm.asc(r.id)])
                ..limit(250))
              .get();
      if (rows.isEmpty) break;
      await database.transaction(() async {
        final assignments = {
          for (final a
              in await (database.select(database.recordCategoryAssignments)
                    ..where(
                      (a) => a.financialRecordId.isIn(rows.map((r) => r.id)),
                    ))
                  .get())
            a.financialRecordId: a,
        };
        final changes = <RecordCategoryAssignmentsCompanion>[];
        for (final row in rows) {
          final old = assignments[row.id];
          if (old != null &&
              old.origin != CategoryAssignmentOrigin.ruleDerived.name) {
            continue;
          }
          final record = repository.toDomain(row);
          final rule = active[(ruleIdentity(record), _kind(record)?.name)];
          if (rule == null ||
              (old?.categoryId == rule.categoryId && old?.ruleId == rule.id)) {
            continue;
          }
          changes.add(
            RecordCategoryAssignmentsCompanion.insert(
              financialRecordId: row.id,
              categoryId: Value(rule.categoryId),
              origin: CategoryAssignmentOrigin.ruleDerived.name,
              ruleId: Value(rule.id),
              assignedAt: Value(DateTime.now()),
            ),
          );
        }
        await database.batch(
          (b) => b.insertAllOnConflictUpdate(
            database.recordCategoryAssignments,
            changes,
          ),
        );
      });
      cursor = rows.last.id;
    }
  }

  String _name(String name) {
    final value = name.trim();
    if (value.isEmpty) throw ArgumentError('Category name must not be empty');
    return value;
  }

  TransactionCategory _category(StoredCategory row) => TransactionCategory(
    id: row.id,
    name: row.displayName,
    kind: CategoryKind.values.byName(row.kind),
    isBuiltIn: row.isBuiltIn,
    isHidden: row.isHidden,
  );
}
