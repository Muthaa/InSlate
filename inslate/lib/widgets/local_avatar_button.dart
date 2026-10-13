import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_preferences_provider.dart';
import '../services/app_preferences.dart';

IconData localAvatarIcon(LocalAvatar avatar) => switch (avatar) {
  LocalAvatar.robot => Icons.smart_toy_rounded,
  LocalAvatar.person => Icons.person_rounded,
  LocalAvatar.face => Icons.face_rounded,
  LocalAvatar.astronaut => Icons.rocket_launch_rounded,
  LocalAvatar.pet => Icons.pets_rounded,
  LocalAvatar.star => Icons.star_rounded,
};

class LocalAvatarButton extends ConsumerWidget {
  final LocalAvatar avatar;
  const LocalAvatarButton({super.key, required this.avatar});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Tooltip(
    message: 'Change avatar',
    child: Semantics(
      label: 'Change avatar',
      button: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => const _AvatarPicker(),
        ),
        child: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.teal,
          child: Icon(localAvatarIcon(avatar), color: Colors.white, size: 32),
        ),
      ),
    ),
  );
}

class _AvatarPicker extends ConsumerStatefulWidget {
  const _AvatarPicker();
  @override
  ConsumerState<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends ConsumerState<_AvatarPicker> {
  bool _saving = false;
  String? _error;

  Future<void> _choose(LocalAvatar avatar) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final preferences = await ref.read(appPreferencesProvider.future);
      await preferences.setLocalAvatar(avatar);
      ref.invalidate(appPreferencesProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Unable to save avatar. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(appPreferencesProvider).valueOrNull?.localAvatar;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Choose your avatar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Close avatar picker',
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              'Pick a little personality for your profile. Saved only on this device.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final avatar in LocalAvatar.values)
                  SizedBox(
                    width: (MediaQuery.sizeOf(context).width - 64) / 3,
                    child: OutlinedButton(
                      key: ValueKey('avatar.${avatar.name}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: AppTheme.darkBlue,
                        backgroundColor: avatar == selected
                            ? AppTheme.teal.withValues(alpha: 0.12)
                            : Colors.white,
                        side: BorderSide(
                          color: avatar == selected
                              ? AppTheme.teal
                              : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _saving ? null : () => _choose(avatar),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: avatar == selected
                                  ? AppTheme.teal
                                  : AppTheme.appBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              localAvatarIcon(avatar),
                              size: 32,
                              color: avatar == selected
                                  ? Colors.white
                                  : AppTheme.darkBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            avatar == LocalAvatar.astronaut
                                ? 'Rocket'
                                : '${avatar.name[0].toUpperCase()}${avatar.name.substring(1)}',
                          ),
                          if (avatar == selected)
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: AppTheme.teal,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
