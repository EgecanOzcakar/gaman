import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Quote {
  final String text;
  final String author;

  /// Work and passage, e.g. "Meditations IV.3".
  final String source;

  /// Public-domain translation the wording comes from.
  final String translator;

  const Quote({
    required this.text,
    required this.author,
    required this.source,
    required this.translator,
  });

  factory Quote.fromJson(Map<String, dynamic> j) => Quote(
        text: j['text'] as String,
        author: j['author'] as String,
        source: j['source'] as String,
        translator: j['translator'] as String,
      );
}

/// Daily quote from the bundled, public-domain collection in
/// `assets/quotes/stoic_quotes.json` (pre-1929 translations only). Works
/// offline; the same quote shows all day and the next one tomorrow.
class QuoteProvider with ChangeNotifier {
  QuoteProvider({AssetBundle? bundle, DateTime Function()? now})
      : _bundle = bundle ?? rootBundle,
        _now = now ?? DateTime.now {
    _load();
  }

  static const asset = 'assets/quotes/stoic_quotes.json';

  final AssetBundle _bundle;
  final DateTime Function() _now;
  List<Quote> _quotes = const [];
  Quote? _currentQuote;

  Quote? get currentQuote => _currentQuote;
  List<Quote> get all => _quotes;

  static Future<List<Quote>> loadAll(AssetBundle bundle) async =>
      (jsonDecode(await bundle.loadString(asset)) as List)
          .map((e) => Quote.fromJson(e as Map<String, dynamic>))
          .toList();

  /// Same quote for a whole calendar day, cycling through the list.
  static Quote forDay(List<Quote> quotes, DateTime day) {
    final days = DateTime.utc(day.year, day.month, day.day)
        .difference(DateTime.utc(2024))
        .inDays;
    return quotes[days % quotes.length];
  }

  Future<void> _load() async {
    try {
      _quotes = await loadAll(_bundle);
      _currentQuote = forDay(_quotes, _now());
    } catch (e) {
      debugPrint('Could not load bundled quotes: $e');
      _currentQuote = const Quote(
        text: 'Look within. Within is the fountain of good, and it will ever '
            'bubble up, if thou wilt ever dig.',
        author: 'Marcus Aurelius',
        source: 'Meditations VII.59',
        translator: 'George Long (1862)',
      );
    }
    notifyListeners();
  }
}
