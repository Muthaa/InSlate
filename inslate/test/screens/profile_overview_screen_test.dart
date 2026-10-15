import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inslate/core/theme/app_theme.dart';
import 'package:inslate/screens/profile/profile_overview_screen.dart';

void main() {
  for (final largeText in [false, true]) {
    for (final dark in [false, true]) {
      testWidgets('Profile grid: large text $largeText, dark $dark', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
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
                ).readAsBytes().then(ByteData.sublistView),
              );
            }
            await body.load();
            final icons = FontLoader('MaterialIcons')
              ..addFont(
                File(
                  '$fontDirectory/MaterialIcons-Regular.otf',
                ).readAsBytes().then(ByteData.sublistView),
              );
            await icons.load();
          });
        }
        final boundary = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            child: RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: dark ? AppTheme.dark() : AppTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(largeText ? 2 : 1)),
                  child: child!,
                ),
                home: const ProfileOverviewScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final budgets = tester.getRect(
          find.byKey(const ValueKey('profile.menu.Budgets')),
        );
        final data = tester.getRect(
          find.byKey(const ValueKey('profile.menu.Your Data')),
        );
        if (largeText) {
          expect(data.top, greaterThan(budgets.bottom));
          expect(data.left, budgets.left);
        } else {
          expect(data.top, budgets.top);
          expect(budgets.height, lessThan(110));
          expect(data.height, budgets.height);
          expect(data.left, greaterThan(budgets.right));
        }
        expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
        final directory = Platform.environment['SLATE_CAPTURE_DIR'];
        if (directory != null && !largeText) {
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(directory).create(recursive: true);
            await File(
              '$directory/profile-${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.ensureVisible(
          find.byKey(const ValueKey('profile.menu.Financial Instruments')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
