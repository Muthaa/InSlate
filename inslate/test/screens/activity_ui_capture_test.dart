import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inslate/core/enums/party_type.dart';
import 'package:inslate/core/enums/record_subtype.dart';
import 'package:inslate/core/theme/app_theme.dart';
import 'package:inslate/database/app_database.dart';
import 'package:inslate/models/activity_filter.dart';
import 'package:inslate/models/financial_period.dart';
import 'package:inslate/models/party.dart';
import 'package:inslate/providers/database_provider.dart';
import 'package:inslate/providers/financial_summary_provider.dart';
import 'package:inslate/repositories/financial_records_repository.dart';
import 'package:inslate/screens/activity/activity_screen.dart';
import 'package:inslate/screens/dashboard/dashboard_screen.dart';
import 'package:inslate/screens/profile/profile_overview_screen.dart';
import '../helpers/widget_capture.dart';
import '../services/financial_summary_service_test.dart' show record;

void main() {
  testWidgets('Activity and compact Home/Profile rendered review captures', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadCaptureFonts(tester);
    await tester.runAsync(
      () => FinancialRecordsRepository(db).saveAll([
        for (var i = 0; i < 123; i++)
          record(
            i.isEven ? RecordSubtype.sendMoney : RecordSubtype.receiveMoney,
            i.isEven ? 1500 : 500,
            party: Party(
              name: i.isEven ? 'Sample merchant' : 'Sample income',
              type: PartyType.business,
            ),
            date: DateTime(2026, 9, 10 - i % 4),
          ),
      ]),
    );
    Future<GlobalKey> open(Widget home) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final boundary = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            selectedMonthProvider.overrideWith((ref) => DateTime(2026, 9)),
          ],
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              home: home,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('lib/assets/images/inslate_logo.png'),
          tester.element(find.byType(Scaffold).first),
        ),
      );
      await tester.pumpAndSettle();
      return boundary;
    }

    try {
      final activity = await open(
        ActivityScreen(
          initialFilter: ActivityFilter(
            period: FinancialPeriod.month(DateTime(2026, 9)),
          ),
        ),
      );
      expect(find.text('123 transactions'), findsOneWidget);
      await captureWidget(tester, activity, 'activity-timeline');
      final search = find.byType(TextField);
      await tester.enterText(search, 'KSh 1500');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('62 transactions'), findsOneWidget);
      await captureWidget(tester, activity, 'activity-amount-search');
      final home = await open(const DashboardScreen());
      await captureWidget(tester, home, 'home-compact-header');
      final profile = await open(const ProfileOverviewScreen());
      await captureWidget(tester, profile, 'profile-compact');
      await tester.tap(find.byTooltip('Change avatar'));
      await tester.pumpAndSettle();
      await captureWidget(tester, profile, 'avatars-four-columns');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() => db.close());
    }
  });
}
