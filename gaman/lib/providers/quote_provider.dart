import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Quote {
  final String text;
  final String author;

  Quote({required this.text, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['content'] ?? '',
      author: json['author'] ?? 'Unknown',
    );
  }
}

class QuoteProvider with ChangeNotifier {
  Quote? _currentQuote;
  DateTime? _lastUpdateDate;
  static const String _quoteKey = 'daily_quote';
  static const String _dateKey = 'quote_date';

  Quote? get currentQuote => _currentQuote;
  bool get shouldUpdateQuote {
    if (_lastUpdateDate == null) return true;
    final now = DateTime.now();
    return _lastUpdateDate!.year != now.year ||
        _lastUpdateDate!.month != now.month ||
        _lastUpdateDate!.day != now.day;
  }

  QuoteProvider() {
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final savedQuote = prefs.getString(_quoteKey);
    final savedDate = prefs.getString(_dateKey);

    if (savedQuote != null && savedDate != null) {
      _currentQuote = Quote.fromJson(json.decode(savedQuote));
      _lastUpdateDate = DateTime.parse(savedDate);
      notifyListeners();
    }

    if (shouldUpdateQuote) {
      await fetchNewQuote();
    }
  }

  Future<void> fetchNewQuote() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.quotable.io/random'),
      );

      if (response.statusCode == 200) {
        final quote = Quote.fromJson(json.decode(response.body));
        _currentQuote = quote;
        _lastUpdateDate = DateTime.now();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_quoteKey, json.encode({
          'content': quote.text,
          'author': quote.author,
        }));
        await prefs.setString(_dateKey, _lastUpdateDate!.toIso8601String());

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching quote: $e');
      // If fetch fails, keep the existing quote
    }
  }
} 