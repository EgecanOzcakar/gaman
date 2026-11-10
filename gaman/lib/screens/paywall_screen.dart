import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/entitlement_service.dart';
import '../theme/app_theme.dart';

/// Gaman Premium upsell. Prices are placeholders ([premiumPlans]) until a
/// billing provider is wired into [EntitlementService].
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static Future<void> show(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const PaywallScreen()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ent = context.watch<EntitlementService>();
    final text = Theme.of(context).textTheme;

    Future<void> buy(String id) async {
      final ok = await ent.purchase(id);
      if (!context.mounted) return;
      if (ok) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.billingUnavailable)));
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.close,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.lg),
        children: [
          Text(l10n.paywallTitle, style: text.headlineMedium),
          const SizedBox(height: Insets.sm),
          Text(l10n.paywallBody, style: text.bodyLarge),
          const SizedBox(height: Insets.lg),
          for (final b in [l10n.paywallPerkInsights, l10n.paywallPerkPrograms, l10n.paywallPerkSupport])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(b),
            ),
          const SizedBox(height: Insets.lg),
          for (final p in premiumPlans)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.md),
              child: FilledButton(
                onPressed: () => buy(p.id),
                child: Text(p.note.isEmpty ? p.price : '${p.price} · ${p.note}'),
              ),
            ),
          TextButton(
            onPressed: () async {
              final ok = await ent.restore();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? l10n.restored : l10n.nothingToRestore)));
            },
            child: Text(l10n.restorePurchases),
          ),
          const SizedBox(height: Insets.sm),
          Text(l10n.paywallFinePrint, style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
