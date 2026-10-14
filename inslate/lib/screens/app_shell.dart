import 'package:flutter/material.dart';
import '../core/design/design_tokens.dart';
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_overview_screen.dart';
import 'insights/insights_screen.dart';
import 'activity/activity_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/import_provider.dart';

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
  late final List<Widget> _screens = [
    DashboardScreen(onOpenProfile: () => _selectTab(3)),
    const SizedBox.shrink(),
    const SizedBox.shrink(),
    const ProfileOverviewScreen(),
  ];

  void _selectTab(int index) {
    setState(() {
      if (index == 1 && !_activityInitialized) {
        _screens[1] = const ActivityScreen();
        _activityInitialized = true;
      }
      if (index == 2 && !_insightsInitialized) {
        _screens[2] = const InsightsScreen();
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
