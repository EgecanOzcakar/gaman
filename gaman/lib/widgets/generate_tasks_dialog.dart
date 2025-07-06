import 'package:flutter/material.dart';

class GenerateTasksDialog extends StatefulWidget {
  const GenerateTasksDialog({super.key});

  @override
  State<GenerateTasksDialog> createState() => _GenerateTasksDialogState();
}

class _GenerateTasksDialogState extends State<GenerateTasksDialog> {
  final _roleController = TextEditingController();
  final _focusController = TextEditingController();
  String _selectedTimeOfDay = 'Morning';

  final List<String> _timeOptions = [
    'Morning',
    'Afternoon',
    'Evening',
    'Night',
  ];

  @override
  void dispose() {
    _roleController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Generate AI Tasks'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help AI understand your context to generate personalized tasks:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Your Role/Profession',
                hintText: 'e.g., Software Developer, Student, Manager',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _focusController,
              decoration: const InputDecoration(
                labelText: 'Current Focus/Goal',
                hintText: 'e.g., Complete project deadline, Study for exam',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTimeOfDay,
              decoration: const InputDecoration(
                labelText: 'Time of Day',
                border: OutlineInputBorder(),
              ),
              items: _timeOptions.map((String time) {
                return DropdownMenuItem<String>(
                  value: time,
                  child: Text(time),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTimeOfDay = newValue!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _roleController.text.trim().isEmpty || 
                     _focusController.text.trim().isEmpty
              ? null
              : () {
                  Navigator.of(context).pop({
                    'role': _roleController.text.trim(),
                    'focus': _focusController.text.trim(),
                    'timeOfDay': _selectedTimeOfDay,
                  });
                },
          child: const Text('Generate'),
        ),
      ],
    );
  }
} 