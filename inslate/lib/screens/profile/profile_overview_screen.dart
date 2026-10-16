import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/design/design_tokens.dart';
import '../../providers/app_preferences_provider.dart';
import '../../widgets/local_avatar_button.dart';
import '../../widgets/responsive_card_grid.dart';
import 'profile_screen.dart';
import 'your_data_screen.dart';
import 'settings_screen.dart';
import '../budgets/budgets_screen.dart';
import '../categories/categories_screen.dart';
import '../instruments/financial_instruments_screen.dart';

class ProfileOverviewScreen extends ConsumerWidget {
  const ProfileOverviewScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: SlateColors.of(context).canvas,
    appBar: AppBar(
      title: const Row(
        children: [
          Icon(Icons.person_rounded, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile'),
                Text(
                  'Your profile, preferences and local data',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.darkBlue,
      foregroundColor: Colors.white,
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ref
            .watch(appPreferencesProvider)
            .when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Loading local profile...'),
              ),
              error: (_, _) => ListTile(
                title: const Text('Unable to load your local profile'),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(appPreferencesProvider),
                ),
              ),
              data: (preferences) => Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.darkBlue.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        LocalAvatarButton(avatar: preferences.localAvatar),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preferences.localDisplayName ??
                                    'Your local profile',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Personal finances, on your device',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit local profile',
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(
                          Icons.phonelink_lock_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Stored locally. No online account or cloud sync.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Manage your finances',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: SlateColors.of(context).ink,
            ),
          ),
        ),
        const _FinanceGrid(),
        const SizedBox(height: 24),
        Text('Settings', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        const _FinanceGrid(settings: true),
      ],
    ),
  );
}

class _FinanceGrid extends StatelessWidget {
  final bool settings;
  const _FinanceGrid({this.settings = false});

  @override
  Widget build(BuildContext context) {
    final items = settings
        ? [
            (
              title: 'Appearance',
              subtitle: 'Motion and display preferences',
              icon: Icons.palette_outlined,
              accent: SlateColors.brandBlue,
              screen: const SettingsScreen(setting: ProfileSetting.appearance),
            ),
            (
              title: 'Privacy & app lock',
              subtitle: 'Protect InSlate with your device screen lock',
              icon: Icons.lock_outline_rounded,
              accent: const Color(0xFF70D9C2),
              screen: const SettingsScreen(setting: ProfileSetting.privacy),
            ),
            (
              title: 'Backup & restore',
              subtitle: 'Future implementation',
              icon: Icons.backup_outlined,
              accent: SlateColors.brandYellow,
              screen: const SettingsScreen(setting: ProfileSetting.backup),
            ),
            (
              title: 'Help & about',
              subtitle: 'Financial definitions, help and licenses',
              icon: Icons.help_outline_rounded,
              accent: SlateColors.brandBlue,
              screen: const SettingsScreen(setting: ProfileSetting.help),
            ),
          ]
        : [
            (
              title: 'Budgets',
              subtitle: 'Monthly expense targets',
              icon: Icons.savings_outlined,
              accent: const Color(0xFF70D9C2),
              screen: const BudgetsScreen(),
            ),
            (
              title: 'Your Data',
              subtitle: 'Review what is stored on this device',
              icon: Icons.storage_outlined,
              accent: SlateColors.brandBlue,
              screen: const YourDataScreen(),
            ),
            (
              title: 'Categories',
              subtitle: 'Manage income and expense categories',
              icon: Icons.category_outlined,
              accent: SlateColors.brandYellow,
              screen: const CategoriesScreen(),
            ),
            (
              title: 'Financial Instruments',
              subtitle: 'Manage your registered accounts and products',
              icon: Icons.account_balance_outlined,
              accent: SlateColors.brandBlue,
              screen: const FinancialInstrumentsScreen(),
            ),
          ];
    final tiles = <Widget>[
      for (final item in items)
        Material(
          color: AppTheme.darkBlue.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white12),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('profile.menu.${item.title}'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => item.screen)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.accent, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          semanticsLabel: '${item.title}. ${item.subtitle}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (item.title == 'Backup & restore')
                          const Text(
                            'Future implementation',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
    return ResponsiveCardGrid(children: tiles);
  }
}
