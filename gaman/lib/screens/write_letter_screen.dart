import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/future_letter_provider.dart';

class WriteLetterScreen extends StatefulWidget {
  const WriteLetterScreen({super.key});

  @override
  State<WriteLetterScreen> createState() => _WriteLetterScreenState();
}

class _WriteLetterScreenState extends State<WriteLetterScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  LetterCondition _condition = LetterCondition.both;
  DateTime? _deliveryDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _needsDate =>
      _condition == LetterCondition.date || _condition == LetterCondition.both;

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık ve mektup metni boş olamaz')),
      );
      return;
    }
    if (_needsDate && _deliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir teslim tarihi seç')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await context.read<FutureLetterProvider>().addLetter(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          condition: _condition,
          deliveryDate: _needsDate ? _deliveryDate : null,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geleceğe mektup yaz')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                hintText: 'Örn: Zor bir gün geçirdiğinde',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Mektubun',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 24),
            Text('Ne zaman teslim edilsin?', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<LetterCondition>(
              segments: const [
                ButtonSegment(value: LetterCondition.date, label: Text('Tarihte')),
                ButtonSegment(value: LetterCondition.lowMood, label: Text('Düşük anda')),
                ButtonSegment(value: LetterCondition.both, label: Text('İkisi de')),
              ],
              selected: {_condition},
              onSelectionChanged: (selection) {
                setState(() => _condition = selection.first);
              },
            ),
            if (_needsDate) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _deliveryDate != null
                        ? 'Teslim tarihi: ${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}'
                        : 'Bir tarih seç',
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) {
                        setState(() => _deliveryDate = picked);
                      }
                    },
                    child: const Text('Seç'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Mektubu kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}