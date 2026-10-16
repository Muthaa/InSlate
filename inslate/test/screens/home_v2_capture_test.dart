import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/theme/app_theme.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/dashboard_provider.dart';
import 'package:inslate/models/financial_breakdown.dart';
import 'package:inslate/providers/financial_summary_provider.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/screens/dashboard/dashboard_screen.dart';
import '../services/financial_summary_service_test.dart' show record;

// Explicitly synthetic records, never presented as a user's real finances.
void main() {
  testWidgets('capture Home using persisted synthetic records', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fontDirectory = Platform.environment['SLATE_FONT_DIR'];
    if (fontDirectory != null) {
      await tester.runAsync(() async {
        final body = FontLoader('Roboto');
        for (final name in [
          'Roboto-Regular.ttf',
          'Roboto-Medium.ttf',
          'Roboto-Bold.ttf',
        ]) {
          body.addFont(
            File(
              '$fontDirectory/$name',
            ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          );
        }
        await body.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            File(
              '$fontDirectory/MaterialIcons-Regular.otf',
            ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          );
        await icons.load();
      });
    }
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final state = Platform.environment['SLATE_CAPTURE_STATE'];
    final now = DateTime.now();
    final period = state == 'empty'
        ? DateTime(now.year, now.month)
        : DateTime(2026, 9);
    if (state != 'empty') {
      await tester.runAsync(
        () => FinancialRecordsRepository(db).saveAll([
          record(RecordSubtype.receiveMoney, 68400, date: period),
          record(RecordSubtype.buyGoods, 18250, fee: 140, date: period),
          record(RecordSubtype.sendMoney, 9600, fee: 180, date: period),
          record(RecordSubtype.mshwariDeposit, 12000, date: period),
          record(RecordSubtype.investmentPurchase, 5000, date: period),
          record(RecordSubtype.fulizaRepayment, 2400, date: period),
          record(RecordSubtype.receiveMoney, 60000, date: DateTime(2026, 8)),
          record(RecordSubtype.buyGoods, 28500, date: DateTime(2026, 8)),
        ]),
      );
    }
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        if (state == 'error')
          dashboardSummaryProvider.overrideWith(
            (ref) => Future<DashboardSummary>.error(
              StateError('Synthetic capture error'),
            ),
          ),
        if (state == 'loading')
          dashboardSummaryProvider.overrideWith(
            (ref) => Completer<DashboardSummary>().future,
          ),
      ],
    );
    container.read(selectedMonthProvider.notifier).state = period;
    final boundary = GlobalKey();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: Platform.environment['SLATE_CAPTURE_DARK'] == 'true'
                ? AppTheme.dark()
                : AppTheme.light(),
            home: const DashboardScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('lib/assets/images/inslate_logo.png'),
        boundary.currentContext!,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final directory = Platform.environment['SLATE_CAPTURE_DIR'];
    if (directory != null) {
      Future<void> capture(String name) async {
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(directory).create(recursive: true);
          await File(
            '$directory/$name.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('home');
      if (Platform.environment['SLATE_CAPTURE_DETAILS'] == 'true') {
        await tester.scrollUntilVisible(
          find.text('Investments'),
          250,
          scrollable: find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .first,
        );
        await Scrollable.ensureVisible(
          tester.element(find.text('Investments')),
          alignment: 0.05,
        );
        await tester.pumpAndSettle();
        await capture('movements');
      }
    }
    container.dispose();
    await tester.pump(Duration.zero);
    await tester.runAsync(() => db.close());
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
