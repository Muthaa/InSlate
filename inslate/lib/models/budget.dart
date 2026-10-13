import 'activity_filter.dart';
import '../core/presentation/financial_presentation.dart';
import 'financial_period.dart';
import 'balance_observation.dart';

class Budget {
  final String id;
  final String? categoryId;
  final String label;
  final int amountMinor;
  final bool overall, isActive, categoryHidden;
  const Budget({
    required this.id,
    required this.categoryId,
    required this.label,
    required this.amountMinor,
    required this.overall,
    required this.isActive,
    required this.categoryHidden,
  });
  bool get available => overall || categoryId != null;
}

String budgetMoney(BigInt amount) => formatKesMinor(amount);

int parseBudgetMoney(String input) {
  final amount = SnapshotMoney.parse(input, 'KES');
  if (amount <= 0) throw ArgumentError('Enter a positive KES amount.');
  return amount;
}

class BudgetProgress {
  final Budget budget;
  final FinancialPeriod period;
  final BigInt? spentMinor;
  final int count;
  const BudgetProgress(this.budget, this.period, this.spentMinor, this.count);
  BigInt? get remainingMinor =>
      spentMinor == null ? null : BigInt.from(budget.amountMinor) - spentMinor!;
  BigInt? get overspentMinor => remainingMinor == null
      ? null
      : remainingMinor!.isNegative
      ? -remainingMinor!
      : BigInt.zero;
  BigInt? get usedBasisPoints => spentMinor == null
      ? null
      : spentMinor! * BigInt.from(10000) ~/ BigInt.from(budget.amountMinor);
  String? get usedPercentage {
    final points = usedBasisPoints;
    if (points == null) return null;
    final digits = points.abs().toString().padLeft(3, '0');
    return '${points.isNegative ? '-' : ''}${digits.substring(0, digits.length - 2)}.${digits.substring(digits.length - 2)}%';
  }

  ActivityFilter? get filter => !budget.available
      ? null
      : ActivityFilter(
          period: period,
          scope: ActivityScope.expenses,
          category: budget.overall
              ? null
              : ActivityCategoryFilter.category(budget.categoryId!),
        );
}
