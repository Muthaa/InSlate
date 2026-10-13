import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/design/design_tokens.dart';
import 'dashboard/dashboard_screen.dart';
import 'insights/insights_screen.dart';
import 'profile/profile_screen.dart';
import '../widgets/local_avatar_button.dart';
import 'budgets/budgets_screen.dart';
import 'profile/your_data_screen.dart';
import 'activity/activity_screen.dart';
import 'categories/categories_screen.dart';
import 'instruments/financial_instruments_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/import_provider.dart';
import '../providers/app_preferences_provider.dart';
import '../models/financial_period.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  bool _activityInitialized = false;
  bool _insightsInitialized = false;
  int _insightsNavigationRevision = 0;
  late final List<Widget> _screens = [
    DashboardScreen(
      onOpenInsights: (period) => _selectTab(2, insightsPeriod: period),
    ),
    const SizedBox.shrink(),
    const SizedBox.shrink(),
    const _MoreScreen(),
  ];

  void _selectTab(int index, {FinancialPeriod? insightsPeriod}) {
    setState(() {
      if (index == 1 && !_activityInitialized) {
        _screens[1] = const ActivityScreen();
        _activityInitialized = true;
      }
      if (index == 2 && (!_insightsInitialized || insightsPeriod != null)) {
        if (insightsPeriod != null) _insightsNavigationRevision++;
        _screens[2] = InsightsScreen(
          initialPeriod: insightsPeriod,
          navigationRevision: _insightsNavigationRevision,
        );
        _insightsInitialized = true;
      }
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final importer = ref.read(importProvider.notifier);

      importer.startIncomingSmsListener();
      importer.catchUpNewMessages();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(importProvider.notifier).catchUpNewMessages();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: SlateColors.of(context).surface,
          border: Border(top: BorderSide(color: SlateColors.of(context).line)),
        ),
        child: NavigationBar(
          backgroundColor: SlateColors.of(context).surface,
          elevation: 0,
          height: 72,
          selectedIndex: _currentIndex,
          onDestinationSelected: _selectTab,
          indicatorColor: SlateColors.of(context).inset,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'Activity',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Insights',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreScreen extends ConsumerWidget {
  const _MoreScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: AppTheme.appBackground,
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
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Manage your finances',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkBlue,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.appBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.savings_outlined,
                color: AppTheme.teal,
                size: 22,
              ),
            ),
            title: const Text(
              'Budgets',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Monthly expense targets'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BudgetsScreen()),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.appBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storage_outlined,
                color: AppTheme.teal,
                size: 22,
              ),
            ),
            title: const Text(
              'Your Data',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Review what is stored on this device'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const YourDataScreen()),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.appBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.category_outlined,
                color: AppTheme.teal,
                size: 22,
              ),
            ),
            title: const Text(
              'Categories',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Manage income and expense categories'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.appBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                color: AppTheme.teal,
                size: 22,
              ),
            ),
            title: const Text(
              'Financial Instruments',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Manage your registered accounts and products',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const FinancialInstrumentsScreen(),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
