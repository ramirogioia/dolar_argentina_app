import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _apiUrlController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _apiUrlController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final apiUrl = ref.read(apiUrlProvider);
    _apiUrlController.text = apiUrl;
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useMockData = ref.watch(useMockDataProvider);

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Usar datos mock'),
              subtitle: const Text(
                'Activa esta opción para usar datos de prueba',
              ),
              value: useMockData,
              onChanged: (value) {
                ref.read(useMockDataProvider.notifier).setValue(value);
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'URL Backend',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiUrlController,
                    decoration: const InputDecoration(
                      hintText: 'Ingresa la URL del backend',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !useMockData,
                    onChanged: (value) {
                      if (!useMockData) {
                        ref.read(apiUrlProvider.notifier).setValue(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fuente futura: Google Sheets Web App '
                    '(Binance P2P + mercados locales)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
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

