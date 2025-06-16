import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Quote {
  final String text;
  final String author;
  final String? authorImageUrl;

  Quote({
    required this.text,
    required this.author,
    this.authorImageUrl,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['text'] ?? '',
      author: json['author'] ?? 'Unknown',
      authorImageUrl: _getAuthorImageUrl(json['author'] ?? 'Unknown'),
    );
  }

//TODO: http exceptions 
  static String? _getAuthorImageUrl(String author) {
    // Map of author names to their Wikimedia Commons image URLs
    final Map<String, String> authorImages = {
      'Marcus Aurelius': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Marcus_Aurelius_Metropolitan_Museum.png/1024px-Marcus_Aurelius_Metropolitan_Museum.png',
      'Epictetus': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Epicteti_Enchiridion_Latinis_versibus_adumbratum_%28Oxford_1715%29_frontispiece.jpg/1024px-Epicteti_Enchiridion_Latinis_versibus_adumbratum_%28Oxford_1715%29_frontispiece.jpg',
      'Seneca': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Seneca-4BC-65AD.jpg/1024px-Seneca-4BC-65AD.jpg',
      'Zeno of Citium': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Zeno_of_Citium_pushkin.jpg/1024px-Zeno_of_Citium_pushkin.jpg',
      'Musonius Rufus': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Musonius_Rufus.jpg/1024px-Musonius_Rufus.jpg',
      'Cato the Younger': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Cato_the_Younger.jpg/1024px-Cato_the_Younger.jpg',
      'Cleanthes': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Cleanthes.jpg/1024px-Cleanthes.jpg',
      'Chrysippus': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/Chrysippus.jpg/1024px-Chrysippus.jpg',
      'Hierocles': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7c/Hierocles.jpg/1024px-Hierocles.jpg',
      'Posidonius': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Posidonius.jpg/1024px-Posidonius.jpg',
      'Panaetius': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/Panaetius.jpg/1024px-Panaetius.jpg',
      'Antipater of Tarsus': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Antipater_of_Tarsus.jpg/1024px-Antipater_of_Tarsus.jpg',
      'Diogenes of Babylon': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d7/Diogenes_of_Babylon.jpg/1024px-Diogenes_of_Babylon.jpg',
      'Aratus of Soli': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Aratus_of_Soli.jpg/1024px-Aratus_of_Soli.jpg',
      'Aristo of Chios': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Aristo_of_Chios.jpg/1024px-Aristo_of_Chios.jpg',
      'Persius': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1c/Persius.jpg/1024px-Persius.jpg',
      'Lucius Annaeus Cornutus': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Lucius_Annaeus_Cornutus.jpg/1024px-Lucius_Annaeus_Cornutus.jpg',
      'Demetrius the Cynic': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Demetrius_the_Cynic.jpg/1024px-Demetrius_the_Cynic.jpg',
      'Agrippinus': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Agrippinus.jpg/1024px-Agrippinus.jpg',
      'Helvidius Priscus': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/Helvidius_Priscus.jpg/1024px-Helvidius_Priscus.jpg',
    };

    // Try to find an exact match first
    String? imageUrl = authorImages[author];
    
    // If no exact match, try to find a partial match
    if (imageUrl == null) {
      for (var key in authorImages.keys) {
        if (author.toLowerCase().contains(key.toLowerCase()) || 
            key.toLowerCase().contains(author.toLowerCase())) {
          imageUrl = authorImages[key];
          break;
        }
      }
    }

    // If still no match, return a default image for unknown authors
    return imageUrl ?? 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Unknown_philosopher.jpg/1024px-Unknown_philosopher.jpg';
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
        Uri.parse('https://stoic-quotes.com/api/quote'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final quote = Quote.fromJson(json.decode(response.body));
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
    } on http.ClientException catch (e) {
      debugPrint('Network error fetching quote: $e');
      _setFallbackQuote();
    } catch (e) {
      debugPrint('Error fetching quote: $e');
      _setFallbackQuote();
    }
  }

  void _setFallbackQuote() {
    _currentQuote = Quote(
      text: "The happiness of your life depends upon the quality of your thoughts.",
      author: "Marcus Aurelius",
      authorImageUrl: Quote._getAuthorImageUrl("Marcus Aurelius"),
    );
    _lastUpdateDate = DateTime.now();
    notifyListeners();
  }
} 