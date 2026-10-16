import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/slate_components.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_lock_provider.dart';
import '../../providers/app_preferences_provider.dart';
import 'your_data_screen.dart';

enum ProfileSetting { appearance, privacy, backup, help, export, contact }

class SettingsScreen extends ConsumerStatefulWidget {
  final ProfileSetting setting;
  const SettingsScreen({super.key, required this.setting});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _saving = false;
  String? _error;
  Future<void> _motion(bool value) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final preferences = await ref.read(appPreferencesProvider.future);
      await preferences.setReduceMotion(value);
      ref.invalidate(appPreferencesProvider);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to save appearance preference. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.setting) {
      ProfileSetting.appearance => 'Appearance',
      ProfileSetting.privacy => 'Privacy & app lock',
      ProfileSetting.backup => 'Backup & restore',
      ProfileSetting.help => 'Help & about',
      ProfileSetting.export => 'Export data',
      ProfileSetting.contact => 'Contact us',
    };
    final colors = SlateColors.of(context);
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.darkBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.setting == ProfileSetting.appearance) ...[
            SlateCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'InSlate appearance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The InSlate blue, yellow and navy palette keeps your financial information familiar.',
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: SlateColors.brandBlue,
                      ),
                      SizedBox(width: 12),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: SlateColors.brandYellow,
                      ),
                      SizedBox(width: 12),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.darkBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ref
                .watch(appPreferencesProvider)
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => TextButton(
                    onPressed: () => ref.invalidate(appPreferencesProvider),
                    child: const Text('Unable to load appearance. Retry'),
                  ),
                  data: (preferences) => SwitchListTile(
                    key: const ValueKey('settings.reduce-motion'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: const Text('Reduce motion'),
                    subtitle: const Text(
                      'Use instant page transitions and reduce supported interface animations. Your phone’s reduced-motion preference is always respected.',
                    ),
                    value: preferences.reduceMotion,
                    onChanged: _saving ? null : _motion,
                  ),
                ),
            const SizedBox(height: 12),
            const Text(
              'Text size follows your phone’s accessibility settings.',
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: colors.spending)),
          ],
          if (widget.setting == ProfileSetting.privacy) ...[
            SlateCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your device. Your data.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your records stay on this device. InSlate has no online account or cloud sync. App lock covers the app when it starts or leaves the foreground.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _privacy(),
            const SizedBox(height: 12),
            const Text(
              'App lock uses your phone PIN, pattern or password. InSlate never stores those credentials. When enabled, screenshots and recent-app previews are blocked. App lock does not encrypt exported files or replace your phone’s screen lock.',
            ),
          ],
          if (widget.setting == ProfileSetting.backup) ...[
            const SlateState(
              kind: SlateStateKind.empty,
              title: 'Future implementation',
              message:
                  'Backup and restore are not available yet. This screen does not export, upload or restore your data.',
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const YourDataScreen()),
              ),
              icon: const Icon(Icons.storage_outlined),
              label: const Text('Review your local data'),
            ),
          ],
          if (widget.setting == ProfileSetting.export ||
              widget.setting == ProfileSetting.contact)
            SlateState(
              kind: SlateStateKind.empty,
              title: 'Future implementation',
              message: widget.setting == ProfileSetting.export
                  ? 'Data export is not available yet. Your records remain stored on this device.'
                  : 'Contact support will be available in a future update.',
            ),
          if (widget.setting == ProfileSetting.help) ...[
            SlateCard(
              child: Column(
                children: [
                  Image.asset(
                    'lib/assets/images/inslate_logo.png',
                    width: 64,
                    height: 64,
                    semanticLabel: 'InSlate logo',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'InSlate',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text('Financial intelligence, on your device.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const ExpansionTile(
              title: Text('Cash flow and balance'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Net cash flow describes income minus spending and fees for the selected period. It is not your account balance. SMS wallet cards show the latest recorded balance, which may differ from your live balance.',
                  ),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text('Savings, investments and loans'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'These movements are shown separately from ordinary income and spending. Moving money into savings is not an ordinary expense, and borrowing is not ordinary income.',
                  ),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text('Missing or older balances'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Only supported balance clauses in stored M-PESA messages create SMS observations. Balance observations in Your Data lets you review history and extract supported balances from messages already stored on your device.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'InSlate',
                applicationIcon: Image.asset(
                  'lib/assets/images/inslate_logo.png',
                  width: 48,
                  height: 48,
                ),
              ),
              child: const Text('Open-source licenses'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _privacy() {
    final lock = ref.watch(appLockProvider);
    final available = ref.watch(deviceUnlockAvailableProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const ValueKey('settings.app-lock'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: const Text('Require device unlock'),
          subtitle: Text(
            lock.enabled
                ? 'App lock is enabled. Verification is required to turn it off.'
                : 'Verify your phone screen lock to enable app lock.',
          ),
          value: lock.enabled,
          onChanged: !lock.ready || lock.busy || available.valueOrNull != true
              ? null
              : ref.read(appLockProvider.notifier).setEnabled,
        ),
        if (available.isLoading || lock.busy) const LinearProgressIndicator(),
        if (available.hasError || available.valueOrNull == false) ...[
          const Text(
            'Device verification is unavailable. Set a PIN, pattern or password in your phone’s screen-lock settings.',
          ),
          TextButton(
            onPressed: () => ref.invalidate(deviceUnlockAvailableProvider),
            child: const Text('Check device lock again'),
          ),
        ],
        if (lock.error != null)
          Text(
            lock.error!,
            style: TextStyle(color: SlateColors.of(context).spending),
          ),
      ],
    );
  }
}
