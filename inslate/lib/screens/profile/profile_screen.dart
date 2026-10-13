import '../../widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_preferences_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String? name,
  ) async {
    var value = name ?? '';
    final form = GlobalKey<FormState>();
    String? error;
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
          icon: Icons.person_outline,
          title: const Text('Local display name'),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name ?? '',
                  onChanged: (text) => value = text,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  enabled: !saving,
                  decoration: InputDecoration(
                    labelText: 'Name (optional)',
                    hintText: 'How should we address you?',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) => (value?.trim().length ?? 0) > 80
                      ? 'Use at most 80 characters.'
                      : null,
                ),
                const Text(
                  'Stored on this device. This does not create an online account.',
                ),
                if (error != null) Text(error!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      setState(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        final preferences = await ref.read(
                          appPreferencesProvider.future,
                        );
                        await preferences.setLocalDisplayName(value);
                        ref.invalidate(appPreferencesProvider);
                        if (context.mounted) Navigator.pop(context);
                      } catch (_) {
                        if (context.mounted) {
                          setState(() {
                            saving = false;
                            error = 'Unable to save name. Please try again.';
                          });
                        }
                      }
                    },
              child: Text(saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: AppTheme.appBackground,
    appBar: AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Local profile'),
          Text(
            'Personalize your InSlate experience',
            style: TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: AppTheme.darkBlue,
      foregroundColor: Colors.white,
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your local profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'InSlate stores your data on this device. There is no online account or cloud synchronization.',
                ),
              ],
            ),
          ),
        ),
        ref
            .watch(appPreferencesProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Unable to load local preferences.'),
              data: (preferences) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const Icon(
                        Icons.badge_outlined,
                        color: AppTheme.teal,
                      ),
                      title: Text(
                        preferences.localDisplayName ??
                            'Add a local display name',
                      ),
                      subtitle: const Text(
                        'Optional; visible only in your local profile',
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () =>
                          _editName(context, ref, preferences.localDisplayName),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const Icon(
                        Icons.sms_outlined,
                        color: AppTheme.darkBlue,
                      ),
                      trailing: Icon(
                        preferences.initialImportCompleted
                            ? Icons.check_circle_outline
                            : Icons.pending_outlined,
                        color: preferences.initialImportCompleted
                            ? AppTheme.teal
                            : Colors.grey,
                      ),
                      title: const Text('Initial SMS import'),
                      subtitle: Text(
                        preferences.initialImportCompleted
                            ? 'Initial setup import completed'
                            : 'Initial setup import not completed',
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    ),
  );
}
