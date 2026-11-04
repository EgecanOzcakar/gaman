import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

/// First-run state. Stored per device, not per account.
class Onboarding {
  static const prefsKey = 'onboarding_done';

  static Future<bool> isDone() async =>
      (await SharedPreferences.getInstance()).getBool(prefsKey) ?? false;

  static Future<void> markDone() async =>
      (await SharedPreferences.getInstance()).setBool(prefsKey, true);
}

/// Three short pages on first launch, then the home screen. The last page
/// asks for notification permission (instead of a cold prompt at startup).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.requestPermission, this.next});

  /// Injected in tests; default to the OS prompt and the home screen.
  final Future<void> Function()? requestPermission;
  final WidgetBuilder? next;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await Onboarding.markDone();
    try {
      await (widget.requestPermission ?? NotificationProvider.requestPermission)();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: widget.next ?? (_) => const MainShell()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      (Icons.landscape_outlined, l10n.onboarding1Title, l10n.onboarding1Body),
      (Icons.self_improvement, l10n.onboarding2Title, l10n.onboarding2Body),
      (Icons.lock_outline, l10n.onboarding3Title, l10n.onboarding3Body),
    ];
    final last = _index == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: Text(l10n.skip)),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final (icon, title, body) in pages)
                    Padding(
                      padding: const EdgeInsets.all(Insets.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: Insets.lg),
                          Text(title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: Insets.md),
                          Text(body,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Semantics(
              label: l10n.pageOf(_index + 1, pages.length),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    Container(
                      margin: const EdgeInsets.all(4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Insets.lg),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: last
                      ? _finish
                      : () => _pages.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut),
                  child: Text(last ? l10n.getStarted : l10n.next),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
