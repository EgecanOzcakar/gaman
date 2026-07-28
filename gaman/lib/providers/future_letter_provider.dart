import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

enum LetterCondition { date, lowMood, both }

class FutureLetter {
  final String id;
  final String title;
  final String content;
  final LetterCondition condition;
  final DateTime? deliveryDate;
  final DateTime createdAt;
  bool delivered;

  FutureLetter({
    required this.id,
    required this.title,
    required this.content,
    required this.condition,
    this.deliveryDate,
    required this.createdAt,
    this.delivered = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'condition': condition.name,
        'deliveryDate': deliveryDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'delivered': delivered,
      };

  factory FutureLetter.fromJson(Map<String, dynamic> json) => FutureLetter(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        condition: LetterCondition.values.firstWhere(
          (c) => c.name == json['condition'],
          orElse: () => LetterCondition.date,
        ),
        deliveryDate:
            json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
        createdAt: DateTime.parse(json['createdAt']),
        delivered: json['delivered'] ?? false,
      );
}

class FutureLetterProvider with ChangeNotifier {
  static const String _storageKey = 'future_letters';
  List<FutureLetter> _letters = [];

  List<FutureLetter> get letters => _letters;
  List<FutureLetter> get pendingLetters =>
      _letters.where((l) => !l.delivered).toList();

  FutureLetterProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    _letters = raw.map((s) => FutureLetter.fromJson(jsonDecode(s))).toList();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _letters.map((l) => jsonEncode(l.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  Future<void> addLetter({
    required String title,
    required String content,
    required LetterCondition condition,
    DateTime? deliveryDate,
  }) async {
    final letter = FutureLetter(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      condition: condition,
      deliveryDate: deliveryDate,
      createdAt: DateTime.now(),
    );
    _letters.add(letter);
    await _persist();
    notifyListeners();
  }

  /// Checks whether a date-based letter is due. Returns the first match, if any.
  FutureLetter? checkDateTriggeredLetter() {
    final now = DateTime.now();
    for (final letter in _letters) {
      if (letter.delivered) continue;
      final isDateType =
          letter.condition == LetterCondition.date || letter.condition == LetterCondition.both;
      if (isDateType && letter.deliveryDate != null && !letter.deliveryDate!.isAfter(now)) {
        return letter;
      }
    }
    return null;
  }

  /// Checks whether a low-mood-based letter should trigger for the given score (1-5 scale).
  /// If multiple letters are eligible, one is picked at random.
  FutureLetter? checkLowMoodTriggeredLetter(int score) {
    if (score > 2) return null;

    final eligible = _letters.where((letter) {
      if (letter.delivered) return false;
      return letter.condition == LetterCondition.lowMood || letter.condition == LetterCondition.both;
    }).toList();

    if (eligible.isEmpty) return null;

    final random = Random();
    return eligible[random.nextInt(eligible.length)];
  }

  Future<void> markDelivered(String id) async {
    final index = _letters.indexWhere((l) => l.id == id);
    if (index == -1) return;
    _letters[index].delivered = true;
    await _persist();
    notifyListeners();
  }
}