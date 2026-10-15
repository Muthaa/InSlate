import 'package:flutter/material.dart';
import '../../models/transaction_category.dart';

/// Purpose identity, independent of amount, ranking, display name or period.
/// Colors identify categories; they do not express whether spending is good/bad.
class CategoryVisual {
  final Color color;
  final IconData icon;
  const CategoryVisual(this.color, this.icon);

  static const _builtIns = <String, CategoryVisual>{
    'builtin.expense.food': CategoryVisual(
      Color(0xFFA65F00),
      Icons.restaurant_outlined,
    ),
    'builtin.expense.transport': CategoryVisual(
      Color(0xFF246EAF),
      Icons.directions_bus_outlined,
    ),
    'builtin.expense.housing': CategoryVisual(
      Color(0xFF5750A2),
      Icons.home_outlined,
    ),
    'builtin.expense.utilities': CategoryVisual(
      Color(0xFF087F8C),
      Icons.bolt_outlined,
    ),
    'builtin.expense.health': CategoryVisual(
      Color(0xFFB8475D),
      Icons.favorite_outline_rounded,
    ),
    'builtin.expense.education': CategoryVisual(
      Color(0xFF7957AD),
      Icons.school_outlined,
    ),
    'builtin.expense.shopping': CategoryVisual(
      Color(0xFF9C4F85),
      Icons.shopping_bag_outlined,
    ),
    'builtin.expense.leisure': CategoryVisual(
      Color(0xFFC06A2B),
      Icons.sports_esports_outlined,
    ),
    'builtin.expense.family': CategoryVisual(
      Color(0xFF21785C),
      Icons.groups_outlined,
    ),
    'builtin.expense.other': CategoryVisual(
      Color(0xFF526274),
      Icons.more_horiz_rounded,
    ),
    'builtin.income.salary': CategoryVisual(
      Color(0xFF087568),
      Icons.work_outline_rounded,
    ),
    'builtin.income.business': CategoryVisual(
      Color(0xFF286EAB),
      Icons.storefront_outlined,
    ),
    'builtin.income.freelance': CategoryVisual(
      Color(0xFF7456A8),
      Icons.laptop_outlined,
    ),
    'builtin.income.gifts': CategoryVisual(
      Color(0xFF9A6C13),
      Icons.card_giftcard_outlined,
    ),
    'builtin.income.refunds': CategoryVisual(
      Color(0xFF527A28),
      Icons.undo_rounded,
    ),
    'builtin.income.other': CategoryVisual(
      Color(0xFF526274),
      Icons.more_horiz_rounded,
    ),
  };

  static CategoryVisual forCategory(String? id, CategoryKind kind) {
    if (id == null) {
      return const CategoryVisual(
        Color(0xFF7D8897),
        Icons.help_outline_rounded,
      );
    }
    final known = _builtIns[id];
    if (known != null) return known;
    // Explicit integer hashing is deterministic across launches/platforms.
    // Custom names can change; the permanent category ID retains its identity.
    var hash = 5381;
    for (final code in '${kind.name}:$id'.codeUnits) {
      hash = ((hash * 33) ^ code) & 0x7FFFFFFF;
    }
    final warm = hash % 160;
    final hue = kind == CategoryKind.income
        ? 110 + hash % 150
        : warm < 80
        ? warm
        : 270 + warm - 80;
    final saturation = 0.52 + ((hash >> 9) % 14) / 100;
    var lightness = 0.36 + ((hash >> 16) % 6) / 100;
    Color shade() =>
        HSLColor.fromAHSL(1, hue.toDouble(), saturation, lightness).toColor();
    var color = shade();
    while (1.05 / (color.computeLuminance() + 0.05) < 4.5 && lightness > 0.2) {
      lightness -= 0.025;
      color = shade();
    }
    return CategoryVisual(
      color,
      kind == CategoryKind.expense
          ? Icons.sell_outlined
          : Icons.payments_outlined,
    );
  }
}
