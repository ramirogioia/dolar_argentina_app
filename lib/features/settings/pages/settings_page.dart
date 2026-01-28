import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_providers.dart';
import '../../../services/fcm_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == 'dark';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            16, 16, 16, 32), // Padding inferior aumentado
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
              title: const Text('Notificaciones Push'),
              subtitle: const Text(
                'Recibe notificaciones sobre la apertura y cierre del mercado del dólar',
              ),
              value: ref.watch(notificationsEnabledProvider),
              onChanged: (value) async {
                // Actualizar el estado primero para que la UI responda inmediatamente
                await ref.read(notificationsEnabledProvider.notifier).setEnabled(value);
                
                // Suscribir o desuscribir del topic según el estado (en background)
                // No esperar para que la UI no se bloquee
                if (value) {
                  FCMService.subscribeToTopic().catchError((e) {
                    print('❌ Error al suscribirse al topic: $e');
                    // Si falla, revertir el estado (opcional, pero mejor UX)
                    // ref.read(notificationsEnabledProvider.notifier).setEnabled(false);
                  });
                } else {
                  FCMService.unsubscribeFromTopic().catchError((e) {
                    print('❌ Error al desuscribirse del topic: $e');
                  });
                }
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
                      final visibility =
                          ref.watch(dollarTypeVisibilityProvider);

                      return ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: (oldIndex, newIndex) {
                          ref
                              .read(dollarTypeOrderProvider.notifier)
                              .reorder(oldIndex, newIndex);
                        },
                        children: order.map((type) {
                          final isVisible = visibility[type] ?? true;

                          return ListTile(
                            key: ValueKey(type),
                            leading: Icon(
                              Icons.drag_handle,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            title: Text(type.displayName),
                            trailing: Switch(
                              value: isVisible,
                              onChanged: (value) {
                                ref
                                    .read(dollarTypeVisibilityProvider.notifier)
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
            child: ExpansionTile(
              leading: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Información de la App',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection(
                        context,
                        'Funcionalidad',
                        'Esta app te permite consultar en tiempo real los diferentes tipos de cotización del dólar en Argentina. Los datos se actualizan automáticamente desde fuentes oficiales y plataformas verificadas.',
                        Icons.currency_exchange,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        context,
                        'Marcadores de Variación',
                        'Los indicadores de variación muestran cómo cambió el precio respecto a hace 24 horas:\n\n'
                            '• Verde ↗️: El precio subió (variación positiva)\n'
                            '• Rojo ↘️: El precio bajó (variación negativa)\n'
                            '• Gris ➖: Sin variación significativa (0.00%)',
                        Icons.trending_up,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        context,
                        'Opciones Disponibles',
                        '• Dólar Oficial: Selecciona diferentes bancos para comparar cotizaciones\n'
                            '• Dólar Cripto: Elige entre plataformas P2P (Binance, KuCoin, OKX, Bitget)\n'
                            '• Personalización: Reordena y oculta tipos de dólar según tus preferencias\n'
                            '• Actualización manual: Desliza hacia abajo para refrescar los datos',
                        Icons.settings_applications,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        context,
                        'Fuentes de Datos',
                        'Los datos provienen directamente de las entidades oficiales y se actualizan periódicamente. La información se obtiene desde el repositorio GitHub del backend y refleja las cotizaciones más recientes del mercado.',
                        Icons.cloud_download,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }
}
