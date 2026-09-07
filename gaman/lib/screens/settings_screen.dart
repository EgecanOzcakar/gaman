import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feature_prefs.dart';
import '../services/gemini_service.dart';

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
    
    setState(() {
      _apiKeyController.text = apiKey ?? '';
      _isConfigured = isConfigured;
    });
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.trim().isEmpty) {
      _showSnackBar('Please enter your Gemini API key');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _geminiService.setApiKey(_apiKeyController.text.trim());
      setState(() {
        _isConfigured = true;
      });
      _showSnackBar('API key saved successfully!');
      
      // Return to previous screen after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      _showSnackBar('Failed to save API key: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
            _PracticesCard(),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Task Generation',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Configure Gemini AI to automatically generate personalized todo tasks based on your role and current focus.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _apiKeyController,
                      decoration: InputDecoration(
                        labelText: 'Gemini API Key',
                        hintText: 'Enter your Gemini API key',
                        border: const OutlineInputBorder(),
                        suffixIcon: _isConfigured
                            ? const Icon(Icons.check_circle, color: Color(0xFF5C8A5C))
                            : null,
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
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
                            : const Text('Save API Key'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How to get your API key:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. Go to Google AI Studio (https://makersuite.google.com/app/apikey)\n'
                            '2. Sign in with your Google account\n'
                            '3. Click "Create API Key"\n'
                            '4. Copy the generated key and paste it above',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Once configured, you can use the "Generate Tasks" button in the Todo screen. '
                      'The AI will ask for your role and current focus, then generate personalized tasks for your day.',
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

class _PracticesCard extends StatelessWidget {
  static const _labels = {
    'meditation': 'Meditation',
    'journal': 'Journal',
    'binaural': 'Binaural Beats',
    'focus': 'Focus Timer',
    'todo': 'Daily Goals',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Consumer<FeaturePrefs>(
        builder: (context, prefs, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Practices on home',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            for (final id in FeaturePrefs.ids)
              SwitchListTile(
                title: Text(_labels[id]!),
                value: prefs.isEnabled(id),
                onChanged: (v) => prefs.setEnabled(id, v),
              ),
          ],
        ),
      ),
    );
  }
}