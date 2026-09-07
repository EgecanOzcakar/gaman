import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _geminiService = GeminiService();
  bool _isLoading = false;
  bool _isConfigured = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await _geminiService.getApiKey();
    final isConfigured = await _geminiService.isConfigured();
    if (!mounted) return;
    setState(() {
      _apiKeyController.text = apiKey ?? '';
      _isConfigured = isConfigured;
    });
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.trim().isEmpty) {
      _showSnackBar('Enter your Gemini API key first');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _geminiService.setApiKey(_apiKeyController.text.trim());
      if (!mounted) return;
      setState(() => _isConfigured = true);
      _showSnackBar('API key saved');
    } catch (e) {
      _showSnackBar('Could not save the API key: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(Insets.md),
        children: [
          _Section(
            title: 'Appearance',
            child: Consumer<ThemeProvider>(
              builder: (context, theme, _) => Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: Insets.sm),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                            value: ThemeMode.system, label: Text('System')),
                        ButtonSegment(
                            value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment(
                            value: ThemeMode.dark, label: Text('Dark')),
                      ],
                      selected: {theme.themeMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => theme.setThemeMode(s.first),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Section(
            title: 'Daily reminder',
            child: Consumer<NotificationProvider>(
              builder: (context, notif, _) {
                final time = notif.scheduledTime;
                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Remind me to reflect'),
                      subtitle: const Text(
                          'A daily nudge to check in and set your goals'),
                      value: notif.isEnabled,
                      onChanged: notif.toggleNotifications,
                    ),
                    ListTile(
                      enabled: notif.isEnabled,
                      title: const Text('Reminder time'),
                      trailing: Text(
                        time == null ? '--:--' : time.format(context),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      onTap: notif.isEnabled
                          ? () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: time ?? const TimeOfDay(hour: 9, minute: 0),
                              );
                              if (picked != null) await notif.setTime(picked);
                            }
                          : null,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Section(
            title: 'Timers',
            child: Consumer<SettingsProvider>(
              builder: (context, s, _) => Column(
                children: [
                  _StepperTile(
                    label: 'Default meditation length',
                    value: '${s.meditationMinutes} min',
                    onMinus: s.meditationMinutes > 5
                        ? () => s.setMeditationMinutes(s.meditationMinutes - 5)
                        : null,
                    onPlus: s.meditationMinutes < 60
                        ? () => s.setMeditationMinutes(s.meditationMinutes + 5)
                        : null,
                  ),
                  _StepperTile(
                    label: 'Breathing pace (in / out)',
                    value: '${s.breathSeconds}s',
                    onMinus: s.breathSeconds > 3
                        ? () => s.setBreathSeconds(s.breathSeconds - 1)
                        : null,
                    onPlus: s.breathSeconds < 8
                        ? () => s.setBreathSeconds(s.breathSeconds + 1)
                        : null,
                  ),
                  _StepperTile(
                    label: 'Default focus length',
                    value: '${s.focusMinutes} min',
                    onMinus: s.focusMinutes > 10
                        ? () => s.setFocusMinutes(s.focusMinutes - 5)
                        : null,
                    onPlus: s.focusMinutes < 60
                        ? () => s.setFocusMinutes(s.focusMinutes + 5)
                        : null,
                  ),
                  _StepperTile(
                    label: 'Long break after',
                    value: '${s.longBreakEvery} sessions',
                    onMinus: s.longBreakEvery > 2
                        ? () => s.setLongBreakEvery(s.longBreakEvery - 1)
                        : null,
                    onPlus: s.longBreakEvery < 8
                        ? () => s.setLongBreakEvery(s.longBreakEvery + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Section(
            title: 'AI task generation',
            child: Padding(
              padding: const EdgeInsets.all(Insets.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add a Gemini API key to generate a daily task list from '
                    'your role and current focus.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Insets.md),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Gemini API key',
                      suffixIcon: _isConfigured
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF5C8A5C))
                          : null,
                    ),
                  ),
                  const SizedBox(height: Insets.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveApiKey,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save API key'),
                    ),
                  ),
                  const SizedBox(height: Insets.sm),
                  Text(
                    'Create a key at aistudio.google.com/app/apikey',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Insets.xs, bottom: Insets.sm),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Card(child: child),
      ],
    );
  }
}

class _StepperTile extends StatelessWidget {
  const _StepperTile({
    required this.label,
    required this.value,
    this.onMinus,
    this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 84,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
