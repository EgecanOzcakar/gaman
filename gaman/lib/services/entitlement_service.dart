import 'package:flutter/foundation.dart';

/// Features that need Gaman Premium.
enum PremiumFeature { advancedInsights, programs }

/// Placeholder plans for the paywall. REPLACE_ME: real product ids and
/// store-localised prices come from the billing provider.
const premiumPlans = [
  (id: 'gaman_premium_yearly', price: r'$24.99 / year', note: 'Best value'),
  (id: 'gaman_premium_monthly', price: r'$3.99 / month', note: ''),
  (id: 'gaman_premium_lifetime', price: r'$49.99 once', note: 'Lifetime'),
];

/// Free vs premium — the only place the app asks. Mock for now: everyone is
/// free; debug builds get a dev toggle in Settings.
///
/// BILLING HOOK: when in_app_purchase or RevenueCat is chosen, seed
/// [_premium] from the store's active entitlements in the constructor (and
/// listen for updates), and implement [purchase] / [restore]. Nothing else in
/// the app needs to change.
class EntitlementService extends ChangeNotifier {
  EntitlementService({bool premium = false}) : _premium = premium;

  bool _premium;
  bool get isPremium => _premium;

  bool has(PremiumFeature feature) => _premium;

  /// Returns whether the user is premium afterwards.
  Future<bool> purchase(String productId) async => _premium; // BILLING HOOK

  Future<bool> restore() async => _premium; // BILLING HOOK

  /// No billing provider exists yet, so purchases always no-op.
  bool get billingAvailable => false;

  /// Dev toggle. Ignored outside debug builds.
  void setDebugPremium(bool value) {
    if (!kDebugMode) return;
    _premium = value;
    notifyListeners();
  }
}
