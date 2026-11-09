import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../data/firestore_repository.dart';
import '../data/repository.dart';
import '../data/sync_status.dart';
import '../l10n/app_localizations.dart';
import '../providers/feature_prefs.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/crash_reporting.dart';
import '../services/data_export.dart';
import '../services/entitlement_service.dart';
import '../theme/app_theme.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _export() async {
    try {
      await exportAllData(context.read<Repository>());
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).exportFailed('$e'));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(Insets.md),
        children: [
          const _BackupSection(),
          const SizedBox(height: Insets.lg),
          _Section(
            title: 'Appearance',
            child: Consumer<ThemeProvider>(
              builder: (context, theme, _) => Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: Insets.sm),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                            value: ThemeMode.system, label: Text('System')),
                        ButtonSegment(
                            value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment(
                            value: ThemeMode.dark, label: Text('Dark')),
                      ],
                      selected: {theme.themeMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => theme.setThemeMode(s.first),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Section(
            title: 'Practices on home',
            child: Consumer<FeaturePrefs>(
              builder: (context, prefs, _) => Column(
                children: [
                  for (final id in FeaturePrefs.ids)
                    SwitchListTile(
                      title: Text(_practiceLabels[id]!),
                      value: prefs.isEnabled(id),
                      onChanged: (v) => prefs.setEnabled(id, v),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Section(
            title: 'Daily reminder',
            child: Consumer<NotificationProvider>(
              builder: (context, notif, _) {
                final time = notif.scheduledTime;
                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Remind me to reflect'),
                      subtitle: const Text(
                          'A daily nudge to check in and set your goals'),
                      value: notif.isEnabled,
                      onChanged: notif.toggleNotifications,
                    ),
                    ListTile(
                      enabled: notif.isEnabled,
                      title: const Text('Reminder time'),
                      trailing: Text(
                        time == null ? '--:--' : time.format(context),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      onTap: notif.isEnabled
                          ? () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: time ??
                                    const TimeOfDay(hour: 9, minute: 0),
                              );
                              if (picked != null) await notif.setTime(picked);
                            }
                          : null,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Section(
            title: 'Timers',
            child: Consumer<SettingsProvider>(
              builder: (context, s, _) => Column(
                children: [
                  _StepperTile(
                    label: 'Default meditation length',
                    value: '${s.meditationMinutes} min',
                    onMinus: s.meditationMinutes > 5
                        ? () => s.setMeditationMinutes(s.meditationMinutes - 5)
                        : null,
                    onPlus: s.meditationMinutes < 60
                        ? () => s.setMeditationMinutes(s.meditationMinutes + 5)
                        : null,
                  ),
                  _StepperTile(
                    label: 'Breathing pace (in / out)',
                    value: '${s.breathSeconds}s',
                    onMinus: s.breathSeconds > 3
                        ? () => s.setBreathSeconds(s.breathSeconds - 1)
                        : null,
                    onPlus: s.breathSeconds < 8
                        ? () => s.setBreathSeconds(s.breathSeconds + 1)
                        : null,
                  ),
                  _StepperTile(
                    label: 'Default focus length',
                    value: '${s.focusMinutes} min',
                    onMinus: s.focusMinutes > 10
                        ? () => s.setFocusMinutes(s.focusMinutes - 5)
                        : null,
                    onPlus: s.focusMinutes < 60
                        ? () => s.setFocusMinutes(s.focusMinutes + 5)
                        : null,
                  ),
                  _StepperTile(
                    label: 'Long break after',
                    value: '${s.longBreakEvery} sessions',
                    onMinus: s.longBreakEvery > 2
                        ? () => s.setLongBreakEvery(s.longBreakEvery - 1)
                        : null,
                    onPlus: s.longBreakEvery < 8
                        ? () => s.setLongBreakEvery(s.longBreakEvery + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Section(
            title: 'Your data',
            child: Padding(
              padding: const EdgeInsets.all(Insets.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "What's stored: your journal, tasks, activity history and "
                    'app settings. They are saved on this device and, once '
                    'the app has connected, in your private cloud account so '
                    'they survive reinstalling. Sign in to use them on another '
                    'phone. They are not shared with anyone.',
                    style: TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: Insets.md),
                  Text(AppLocalizations.of(context).exportExplainer),
                  const SizedBox(height: Insets.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _export,
                      icon: const Icon(Icons.ios_share),
                      label: Text(AppLocalizations.of(context).exportAllData),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          const _PremiumSection(),
          const SizedBox(height: Insets.lg),
          const _PrivacySection(),
          const SizedBox(height: Insets.lg),
          const _DeleteAccountSection(),
        ],
      ),
    );
  }
}

class _BackupSection extends StatelessWidget {
  const _BackupSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Back up your progress',
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (!auth.available) {
            return const ListTile(
              leading: Icon(Icons.cloud_off_outlined),
              title: Text('Cloud backup is unavailable on this build'),
              subtitle: Text('Your progress is saved on this device.'),
            );
          }
          if (auth.isAnonymous) {
            return Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.cloud_upload_outlined),
                  title: Text('Your progress is on this device only'),
                  subtitle: Text(
                      'Sign in to keep it safe and use it on another phone.'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Insets.md, 0, Insets.md, Insets.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          _link(context, auth, AuthProviderKind.google),
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in with Google'),
                    ),
                  ),
                ),
                if (AuthService.appleSignInEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Insets.md, 0, Insets.md, Insets.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            _link(context, auth, AuthProviderKind.apple),
                        icon: const Icon(Icons.apple),
                        label: Text(AppLocalizations.of(context).signInApple),
                      ),
                    ),
                  ),
              ],
            );
          }
          return Column(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_done_outlined),
                title: Text('Backed up as ${auth.accountLabel ?? 'your account'}'),
                subtitle: StreamBuilder<SyncStatus>(
                  stream: context.read<Repository>().watchSyncStatus(),
                  builder: (context, snap) => Text(switch (snap.data) {
                    SyncStatus.syncing => 'Syncing…',
                    SyncStatus.offline =>
                      'Offline — changes are saved on this device',
                    _ => 'Synced',
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Insets.md, 0, Insets.md, Insets.md),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: auth.signOut,
                    child: const Text('Sign out'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _link(
      BuildContext context, AuthService auth, AuthProviderKind kind) async {
    final result = await auth.link(kind);
    if (!context.mounted) return;
    switch (result) {
      case LinkResult.linked:
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your progress is backed up')));
      case LinkResult.conflict:
        await _showConflictDialog(context, auth);
      case LinkResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not sign in — try again')));
      case LinkResult.cancelled:
      case LinkResult.unavailable:
        break;
    }
  }
}

Future<void> _showConflictDialog(BuildContext context, AuthService auth) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('That account already has progress'),
      content: const Text(
        'This Google account was used on another device. You can switch to '
        "that account's progress now — this device's local progress stays "
        'on this device.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            auth.cancelConflict();
            Navigator.pop(context);
          },
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () async {
            await auth.useAccountAfterConflict();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text("Use my account's data"),
        ),
      ],
    ),
  );
}

@visibleForTesting
class BackupSectionForTest extends StatelessWidget {
  const BackupSectionForTest({super.key});
  @override
  Widget build(BuildContext context) => const _BackupSection();
}


class _PremiumSection extends StatelessWidget {
  const _PremiumSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ent = context.watch<EntitlementService>();
    return _Section(
      title: l10n.premiumTitle,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(ent.isPremium ? l10n.premiumActive : l10n.premiumFree),
            trailing: ent.isPremium ? null : const Icon(Icons.chevron_right),
            onTap: ent.isPremium ? null : () => PaywallScreen.show(context),
          ),
          if (kDebugMode)
            SwitchListTile(
              title: Text(l10n.devPremiumToggle),
              value: ent.isPremium,
              onChanged: ent.setDebugPremium,
            ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final crash = context.watch<CrashReporting>();
    return _Section(
      title: l10n.privacyTitle,
      child: Column(
        children: [
          SwitchListTile(
            title: Text(l10n.crashReportsTitle),
            subtitle: Text(l10n.crashReportsBody),
            value: crash.enabled,
            onChanged: crash.available ? crash.setEnabled : null,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(Uri.parse(AppConfig.privacyUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.terms),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(Uri.parse(AppConfig.termsUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.licenses),
            onTap: () => showLicensePage(context: context),
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountSection extends StatelessWidget {
  const _DeleteAccountSection();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.available) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final danger = Theme.of(context).colorScheme.error;
    return _Section(
      title: l10n.deleteAccountTitle,
      child: ListTile(
        leading: Icon(Icons.delete_forever_outlined, color: danger),
        title: Text(l10n.deleteAccountButton, style: TextStyle(color: danger)),
        subtitle: Text(l10n.deleteAccountSubtitle),
        onTap: () => _confirmAndDelete(context, auth),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, AuthService auth) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteAccountButton),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final result = await auth.deleteAccount(deleteUserData);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(switch (result) {
        DeleteResult.deleted => l10n.deleteAccountDone,
        DeleteResult.cancelled => l10n.deleteAccountCancelled,
        _ => l10n.deleteAccountFailed,
      }),
    ));
  }
}

/// Removes everything stored for [uid]: the cloud copy and this device's.
Future<void> deleteUserData(String uid) async {
  await FirestoreRepository(uid: uid).deleteAllUserData();
  await (await SharedPreferences.getInstance()).clear();
}

const _practiceLabels = {
  'meditation': 'Breathe (meditation)',
  'journal': 'Journal',
  'binaural': 'Sound (ambient tracks)',
  'focus': 'Focus Timer',
  'todo': 'One task that matters',
};

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Insets.xs, bottom: Insets.sm),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Card(child: child),
      ],
    );
  }
}

class _StepperTile extends StatelessWidget {
  const _StepperTile({
    required this.label,
    required this.value,
    this.onMinus,
    this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: AppLocalizations.of(context).decrease(label),
            onPressed: onMinus,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 84,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).increase(label),
            onPressed: onPlus,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
