import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Quote {
  final String text;
  final String author;

  Quote({required this.text, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['text'] ?? '',
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
      // Create a custom HttpClient that bypasses certificate verification
      final client = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      
      // Create a request
      final request = await client.getUrl(
        Uri.parse('https://stoic-quotes.com/api/quote'),
      );
      
      // Get the response
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final quote = Quote.fromJson(json.decode(responseBody));
        _currentQuote = quote;
        _lastUpdateDate = DateTime.now();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_quoteKey, json.encode({
          'text': quote.text,
          'author': quote.author,
        }));
        await prefs.setString(_dateKey, _lastUpdateDate!.toIso8601String());

        notifyListeners();
      } else {
        debugPrint('Failed to fetch quote: ${response.statusCode}');
        _setFallbackQuote();
      }
      
      client.close();
    } catch (e) {
      debugPrint('Error fetching quote: $e');
      _setFallbackQuote();
    }
  }

  void _setFallbackQuote() {
    _currentQuote = Quote(
      text: "The happiness of your life depends upon the quality of your thoughts.",
      author: "Marcus Aurelius",
    );
    _lastUpdateDate = DateTime.now();
    notifyListeners();
  }
} 