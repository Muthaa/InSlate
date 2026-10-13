import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inslate/services/app_preferences.dart';
import 'package:inslate/widgets/local_avatar_button.dart';

void main() {
  test('avatar preference persists and unknown values use robot', () async {
    SharedPreferences.setMockInitialValues({'local_avatar': 'unknown'});
    final store = await SharedPreferences.getInstance();
    final preferences = AppPreferences(store);
    expect(preferences.localAvatar, LocalAvatar.robot);
    await preferences.setLocalAvatar(LocalAvatar.pet);
    expect(AppPreferences(store).localAvatar, LocalAvatar.pet);
  });
  testWidgets(
    'avatar opens picker, cancels unchanged and saves explicit selection',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: LocalAvatarButton(avatar: LocalAvatar.robot)),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Change avatar'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your avatar'), findsOneWidget);
      await tester.tap(find.byTooltip('Close avatar picker'));
      await tester.pumpAndSettle();
      final store = await SharedPreferences.getInstance();
      expect(AppPreferences(store).localAvatar, LocalAvatar.robot);
      await tester.tap(find.byTooltip('Change avatar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('avatar.face')));
      await tester.pumpAndSettle();
      expect(find.text('Choose your avatar'), findsNothing);
      expect(AppPreferences(store).localAvatar, LocalAvatar.face);
    },
  );
}
