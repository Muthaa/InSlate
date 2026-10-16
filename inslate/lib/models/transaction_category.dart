enum CategoryKind { expense, income }

enum CategoryAssignmentOrigin { manual, ruleDerived, manualUncategorized }

/// User-facing purpose, independent of transaction type and subtype.
class TransactionCategory {
  final String id, name;
  final CategoryKind kind;
  final bool isBuiltIn, isHidden;
  const TransactionCategory({
    required this.id,
    required this.name,
    required this.kind,
    this.isBuiltIn = false,
    this.isHidden = false,
  });
}

class CategoryAssignment {
  final int financialRecordId;
  final String? categoryId;
  final int? ruleId;
  final CategoryAssignmentOrigin origin;
  final DateTime assignedAt;
  const CategoryAssignment({
    required this.financialRecordId,
    required this.categoryId,
    required this.origin,
    required this.assignedAt,
    this.ruleId,
  });
}

/// IDs are permanent, even when the user edits the display name or visibility.
const builtInCategories = [
  TransactionCategory(
    id: 'builtin.expense.food',
    name: 'Food & groceries',
    kind: CategoryKind.expense,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.expense.transport',
    name: 'Transport',
    kind: CategoryKind.expense,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.expense.housing',
    name: 'Housing',
    kind: CategoryKind.expense,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.expense.utilities',
    name: 'Bills & utilities',
    kind: CategoryKind.expense,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.expense.health',
    name: 'Health',
    kind: CategoryKind.expense,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.expense.education',
    name: 'Education',
    kind: CategoryKind.expense,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.expense.shopping',
    name: 'Shopping',
    kind: CategoryKind.expense,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.expense.leisure',
    name: 'Leisure',
    kind: CategoryKind.expense,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.expense.family',
    name: 'Family & support',
    kind: CategoryKind.expense,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.expense.other',
    name: 'Other expenses',
    kind: CategoryKind.expense,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.income.salary',
    name: 'Salary',
    kind: CategoryKind.income,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.income.business',
    name: 'Business income',
    kind: CategoryKind.income,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.income.freelance',
    name: 'Freelance income',
    kind: CategoryKind.income,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.income.gifts',
    name: 'Gifts & support',
    kind: CategoryKind.income,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.income.refunds',
    name: 'Refunds',
    kind: CategoryKind.income,
    isBuiltIn: true,
  ),
  TransactionCategory(
    id: 'builtin.income.other',
    name: 'Other income',
    kind: CategoryKind.income,
    isBuiltIn: true,
  ),
];
