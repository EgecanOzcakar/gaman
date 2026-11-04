import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/providers/quote_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled collection loads offline with source and translator', () async {
    final quotes = await QuoteProvider.loadAll(rootBundle);
    expect(quotes.length, greaterThanOrEqualTo(60));
    for (final q in quotes) {
      expect(q.text, isNotEmpty);
      expect(q.source, isNotEmpty);
      expect(['Marcus Aurelius', 'Epictetus', 'Seneca'], contains(q.author));
      // Only pre-1929 (public-domain) translations.
      expect(q.translator, anyOf(contains('George Long'), contains('Gummere')));
    }
  });

  test('one quote per day, a different one tomorrow', () async {
    final quotes = await QuoteProvider.loadAll(rootBundle);
    final a = QuoteProvider.forDay(quotes, DateTime(2026, 11, 4, 8));
    final b = QuoteProvider.forDay(quotes, DateTime(2026, 11, 4, 22));
    final c = QuoteProvider.forDay(quotes, DateTime(2026, 11, 5));
    expect(identical(a, b), isTrue);
    expect(identical(a, c), isFalse);
  });

  test('provider exposes the day\'s quote', () async {
    final p = QuoteProvider(now: () => DateTime(2026, 1, 1));
    await pumpEventQueue();
    expect(p.currentQuote, isNotNull);
  });
}
