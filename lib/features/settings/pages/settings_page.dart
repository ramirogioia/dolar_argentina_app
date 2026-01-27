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
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == 'dark';

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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), // Padding inferior aumentado
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Modo Oscuro'),
              subtitle: const Text(
                'Activa el modo oscuro para una mejor experiencia en ambientes con poca luz',
              ),
              value: isDarkMode,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).setThemeMode(
                  value ? 'dark' : 'light',
                );
              },
            ),
          ),
          const SizedBox(height: 16),
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
                    'Tipos de Dólar Visibles',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona qué tipos de dólar quieres ver en la pantalla principal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final order = ref.watch(dollarTypeOrderProvider);
                      final visibility = ref.watch(dollarTypeVisibilityProvider);
                      
                      return ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: (oldIndex, newIndex) {
                          ref.read(dollarTypeOrderProvider.notifier)
                              .reorder(oldIndex, newIndex);
                        },
                        children: order.map((type) {
                          final isVisible = visibility[type] ?? true;
                          
                          return ListTile(
                            key: ValueKey(type),
                            leading: Icon(
                              Icons.drag_handle,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            title: Text(type.displayName),
                            trailing: Switch(
                              value: isVisible,
                              onChanged: (value) {
                                ref.read(dollarTypeVisibilityProvider.notifier)
                                    .setVisibility(type, value);
                              },
                            ),
                          );
                        }).toList(),
                      );
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

