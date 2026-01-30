import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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
          const SizedBox(height: 16),
          // Sección de debugging de notificaciones (solo en modo debug)
          Card(
            color: Colors.orange.shade50,
            child: ExpansionTile(
              leading: Icon(
                Icons.bug_report,
                color: Colors.orange.shade700,
              ),
              title: Text(
                'Debug: Notificaciones',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
              ),
              subtitle: const Text(
                'Herramientas para diagnosticar problemas de notificaciones',
                style: TextStyle(fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FutureBuilder<String?>(
                        future: FCMService.getToken(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          
                          final token = snapshot.data;
                          
                          if (token == null || token.isEmpty) {
                            return Column(
                              children: [
                                const Text(
                                  '❌ Token FCM no disponible',
                                  style: TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await FCMService.initialize();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Reinicializando FCM... Revisa los logs'),
                                        ),
                                      );
                                    }
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reinicializar FCM'),
                                ),
                              ],
                            );
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                '✅ Token FCM disponible',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SelectableText(
                                  token,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: token));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('✅ Token copiado al portapapeles'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.copy),
                                      label: const Text('Copiar Token'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          await FCMService.subscribeToTopic();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('✅ Suscrito al topic "all_users"'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('❌ Error: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.notifications_active),
                                      label: const Text('Suscribir'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  FCMService.diagnosticar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('🔍 Revisa los logs de la consola'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.medical_services),
                                label: const Text('Ejecutar Diagnóstico Completo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ExpansionTile(
              leading: Icon(
                Icons.link,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Fuentes de Información',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              subtitle: const Text(
                'Enlaces a las fuentes oficiales de los datos',
                style: TextStyle(fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSourceSection(
                        context,
                        'Dólar Oficial',
                        [
                          {'nombre': 'Banco Nación', 'url': 'https://www.bna.com.ar/Personas'},
                          {'nombre': 'BBVA Argentina', 'url': 'https://www.bbva.com.ar/personas/productos/inversiones/cotizacion-moneda-extranjera.html'},
                          {'nombre': 'Banco Supervielle', 'url': 'https://www.supervielle.com.ar/personas/inversiones/moneda-extranjera/compra-y-venta'},
                          {'nombre': 'Banco Patagonia', 'url': 'https://ebankpersonas.bancopatagonia.com.ar/eBanking/usuarios/cotizacionMonedaExtranjera.htm'},
                          {'nombre': 'Banco Provincia', 'url': 'https://www.bancoprovincia.com.ar/productos/inversiones/dolares_bip/dolares_bip_info_gral'},
                          {'nombre': 'Banco Ciudad', 'url': 'https://bancociudad.com.ar/institucional/'},
                          {'nombre': 'Banco Hipotecario', 'url': 'https://www.hipotecario.com.ar/buho-one/inversiones/cotizaciones/'},
                          {'nombre': 'ICBC Argentina', 'url': 'https://www.icbc.com.ar/personas/start'},
                        ],
                        Icons.account_balance,
                      ),
                      const SizedBox(height: 24),
                      _buildSourceSection(
                        context,
                        'Dólar Cripto',
                        [
                          {'nombre': 'Binance', 'url': 'https://p2p.binance.com'},
                          {'nombre': 'KuCoin', 'url': 'https://www.kucoin.com'},
                          {'nombre': 'Bybit', 'url': 'https://www.bybit.com'},
                          {'nombre': 'OKX', 'url': 'https://www.okx.com'},
                          {'nombre': 'Bitget', 'url': 'https://www.bitget.com'},
                        ],
                        Icons.currency_bitcoin,
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

  Widget _buildSourceSection(
    BuildContext context,
    String title,
    List<Map<String, String>> sources,
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
        const SizedBox(height: 12),
        ...sources.map((source) {
          return Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 8),
            child: InkWell(
              onTap: () async {
                final url = Uri.parse(source['url']!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('No se pudo abrir el enlace: ${source['url']}'),
                      ),
                    );
                  }
                }
              },
              child: Row(
                children: [
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      source['nombre']!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
