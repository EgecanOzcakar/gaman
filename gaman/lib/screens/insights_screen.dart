import 'package:flutter/material.dart';
import '../services/mood_correlation_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _service = MoodCorrelationService();
  CorrelationResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _service.computeTaskMoodCorrelation();
    if (mounted) {
      setState(() {
        _result = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İçgörüler')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: (_result != null && _result!.hasEnoughData)
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Görevlerin ve ruh halin',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tüm görevlerini tamamladığın günlerde ortalama ruh halin '
                              '${_result!.avgMoodHighCompletion.toStringAsFixed(1)}/5.',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Görevlerinin çoğunu tamamlamadığın günlerde ortalama ruh halin '
                              '${_result!.avgMoodLowCompletion.toStringAsFixed(1)}/5.',
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '(${_result!.highCompletionDays} tam gün, ${_result!.lowCompletionDays} eksik gün karşılaştırıldı)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'İçgörüler için biraz daha veriye ihtiyacın var',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Mood check-in\'lere cevap verip görevlerini işaretlemeye devam et, '
                              'birkaç gün içinde burada kişisel bir içgörü göreceksin.',
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
    );
  }
}