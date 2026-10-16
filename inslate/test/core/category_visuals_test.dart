import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/presentation/category_visuals.dart';
import 'package:inslate/models/transaction_category.dart';

void main() {
  for (final kind in CategoryKind.values) {
    test(
      '${kind.name} built-in chart categories have distinct colors and visible contrast',
      () {
        final categories = builtInCategories
            .where((c) => c.kind == kind)
            .toList();
        final visuals = categories
            .map((c) => CategoryVisual.forCategory(c.id, kind))
            .toList();
        expect(
          visuals.map((v) => v.color).toSet(),
          hasLength(categories.length),
        );
        for (final visual in visuals) {
          expect(
            (Colors.white.computeLuminance() + 0.05) /
                (visual.color.computeLuminance() + 0.05),
            greaterThanOrEqualTo(3),
          );
        }
        expect(
          CategoryVisual.forCategory(null, kind).color,
          isNot(visuals.last.color),
        );
      },
    );
  }
  test(
    'custom category colors remain visible on their actual tinted icon surfaces',
    () {
      for (final kind in CategoryKind.values) {
        for (var index = 0; index < 200; index++) {
          final color = CategoryVisual.forCategory('custom-$index', kind).color;
          final background = Color.alphaBlend(
            color.withValues(alpha: 0.10),
            Colors.white,
          );
          expect(
            (background.computeLuminance() + 0.05) /
                (color.computeLuminance() + 0.05),
            greaterThanOrEqualTo(3),
          );
        }
      }
    },
  );
}
