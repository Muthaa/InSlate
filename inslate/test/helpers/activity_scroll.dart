import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> scrollActivityToEnd(WidgetTester tester) async {
  final list = find.byKey(const ValueKey('activity.timeline'));
  for (var i = 0; i < 12; i++) {
    if (list.evaluate().isEmpty) return;
    final controller = tester.widget<ListView>(list).controller!;
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
  }
}
