import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inslate/services/app_preferences.dart';
import 'package:inslate/widgets/local_avatar_button.dart';

void main() {
  test('avatar preference persists and unknown values use rocket', () async {
    SharedPreferences.setMockInitialValues({'local_avatar': 'unknown'});
    final store = await SharedPreferences.getInstance();
    final preferences = AppPreferences(store);
    expect(preferences.localAvatar, LocalAvatar.astronaut);
    await preferences.setLocalAvatar(LocalAvatar.pet);
    expect(AppPreferences(store).localAvatar, LocalAvatar.pet);
  });
  test('unset avatar uses rocket and saved robot remains selected', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SharedPreferences.getInstance();
    expect(AppPreferences(store).localAvatar, LocalAvatar.astronaut);
    await AppPreferences(store).setLocalAvatar(LocalAvatar.robot);
    expect(AppPreferences(store).localAvatar, LocalAvatar.robot);
  });
  testWidgets(
    'avatar opens picker, cancels unchanged and saves explicit selection',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LocalAvatarButton(avatar: LocalAvatar.astronaut),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Change avatar'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your avatar'), findsOneWidget);
      expect(LocalAvatar.values, hasLength(16));
      final first = tester.getRect(find.byKey(const ValueKey('avatar.robot')));
      final fourth = tester.getRect(
        find.byKey(const ValueKey('avatar.astronaut')),
      );
      final fifth = tester.getRect(find.byKey(const ValueKey('avatar.pet')));
      expect(fourth.top, first.top);
      expect(fifth.top, greaterThan(first.bottom));
      await tester.tap(find.byTooltip('Close avatar picker'));
      await tester.pumpAndSettle();
      final store = await SharedPreferences.getInstance();
      expect(AppPreferences(store).localAvatar, LocalAvatar.astronaut);
      await tester.tap(find.byTooltip('Change avatar'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('avatar.face')));
      await tester.tap(find.byKey(const ValueKey('avatar.face')));
      await tester.pumpAndSettle();
      expect(find.text('Choose your avatar'), findsNothing);
      expect(AppPreferences(store).localAvatar, LocalAvatar.face);
    },
  );
  testWidgets(
    'all sixteen avatars fit four columns with large text and a new avatar persists',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const Scaffold(
              body: LocalAvatarButton(avatar: LocalAvatar.astronaut),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Change avatar'));
      await tester.pumpAndSettle();
      for (final avatar in LocalAvatar.values) {
        expect(find.byKey(ValueKey('avatar.${avatar.name}')), findsOneWidget);
      }
      expect(
        tester.getRect(find.byKey(const ValueKey('avatar.robot'))).top,
        tester.getRect(find.byKey(const ValueKey('avatar.astronaut'))).top,
      );
      final last = find.byKey(const ValueKey('avatar.mountain'));
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(
        AppPreferences(await SharedPreferences.getInstance()).localAvatar,
        LocalAvatar.mountain,
      );
    },
  );
}
