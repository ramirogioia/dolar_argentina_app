import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_providers.dart';
import '../../../services/fcm_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  /// Mostrar sección "Debug: Notificaciones" en Ajustes. Cambiar a true para volver a usarla.
  static const bool _showDebugNotifications = false;

  late Future<AuthorizationStatus> _notificationPermissionFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationPermissionFuture =
        FCMService.getNotificationPermissionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Al volver de Ajustes, refrescar estado del permiso
      setState(() {
        _notificationPermissionFuture =
            FCMService.getNotificationPermissionStatus();
      });
    }
  }

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Notificaciones Push'),
                  subtitle: const Text(
                    'Recibe notificaciones sobre la apertura y cierre del mercado del dólar',
                  ),
                  value: ref.watch(notificationsEnabledProvider),
                  onChanged: (value) async {
                    await ref
                        .read(notificationsEnabledProvider.notifier)
                        .setEnabled(value);
                    if (value) {
                      FCMService.subscribeToTopic().catchError((e) {
                        print('❌ Error al suscribirse al topic: $e');
                      });
                    } else {
                      FCMService.unsubscribeFromTopic().catchError((e) {
                        print('❌ Error al desuscribirse del topic: $e');
                      });
                    }
                  },
                ),
                // Si el permiso está denegado (ej. usuario tocó "No" en iOS), ofrecer abrir Ajustes
                FutureBuilder<AuthorizationStatus>(
                  future: _notificationPermissionFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData ||
                        snapshot.data != AuthorizationStatus.denied) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      leading: Icon(
                        Icons.settings,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        Platform.isIOS
                            ? 'Abrir Ajustes del iPhone'
                            : 'Abrir Ajustes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        'Las notificaciones están desactivadas. Actívalas en Ajustes para recibir alertas.',
                      ),
                      onTap: () => AppSettings.openAppSettings(),
                    );
                  },
                ),
              ],
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
            child: ListTile(
              leading: Icon(
                Icons.email,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Contacto y Publicidad',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              subtitle: const Text(
                'Por cualquier consulta o tema de publicidad podés escribirnos por correo',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () => _openContactEmail(context),
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
                        'Consultá en tiempo real las cotizaciones del dólar en Argentina: blue, oficial, cripto, tarjeta, MEP y CCL. Los valores se actualizan automáticamente para que siempre tengas la información al día.',
                        Icons.currency_exchange,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        context,
                        'Marcadores de variación',
                        'Cada tipo de dólar muestra cómo varió el precio respecto a las últimas 24 horas:\n\n'
                            '• Verde ↗️: subió\n'
                            '• Rojo ↘️: bajó\n'
                            '• Gris ➖: sin cambio significativo',
                        Icons.trending_up,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        context,
                        'Opciones disponibles',
                        '• Dólar Oficial: elegí el banco para ver su cotización (Nación, BBVA, Provincia, etc.)\n'
                            '• Dólar Cripto: elegí la plataforma P2P (Binance, KuCoin, Bybit, OKX, Bitget)\n'
                            '• Personalización: reordená y ocultá tipos de dólar en Ajustes\n'
                            '• Actualización: deslizá hacia abajo en la pantalla principal para refrescar',
                        Icons.settings_applications,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        context,
                        'Fuentes de datos',
                        'Las cotizaciones provienen directamente de las fuentes oficiales (bancos, entidades y plataformas verificadas). La información se actualiza de forma recurrente para que los valores mostrados reflejen el mercado real.',
                        Icons.cloud_download,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Sección de debugging de notificaciones (oculta; poner _showDebugNotifications = true para mostrarla)
          if (_showDebugNotifications) ...[
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
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Reinicializando FCM... Revisa los logs'),
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
                                          Clipboard.setData(
                                              ClipboardData(text: token));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  '✅ Token copiado al portapapeles'),
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
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      '✅ Suscrito al topic "all_users"'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text('❌ Error: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(
                                            Icons.notifications_active),
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
                                        content: Text(
                                            '🔍 Revisa los logs de la consola'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.medical_services),
                                  label: const Text(
                                      'Ejecutar Diagnóstico Completo'),
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
          ],
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
                          {
                            'nombre': 'Banco Nación',
                            'url': 'https://www.bna.com.ar/Personas'
                          },
                          {
                            'nombre': 'BBVA Argentina',
                            'url':
                                'https://www.bbva.com.ar/personas/productos/inversiones/cotizacion-moneda-extranjera.html'
                          },
                          {
                            'nombre': 'Banco Supervielle',
                            'url':
                                'https://www.supervielle.com.ar/personas/inversiones/moneda-extranjera/compra-y-venta'
                          },
                          {
                            'nombre': 'Banco Patagonia',
                            'url':
                                'https://ebankpersonas.bancopatagonia.com.ar/eBanking/usuarios/cotizacionMonedaExtranjera.htm'
                          },
                          {
                            'nombre': 'Banco Provincia',
                            'url':
                                'https://www.bancoprovincia.com.ar/productos/inversiones/dolares_bip/dolares_bip_info_gral'
                          },
                          {
                            'nombre': 'Banco Ciudad',
                            'url': 'https://bancociudad.com.ar/institucional/'
                          },
                          {
                            'nombre': 'Banco Hipotecario',
                            'url':
                                'https://www.hipotecario.com.ar/buho-one/inversiones/cotizaciones/'
                          },
                          {
                            'nombre': 'ICBC Argentina',
                            'url': 'https://www.icbc.com.ar/personas/start'
                          },
                        ],
                        Icons.account_balance,
                      ),
                      const SizedBox(height: 24),
                      _buildSourceSection(
                        context,
                        'Dólar Cripto',
                        [
                          {
                            'nombre': 'Binance',
                            'url': 'https://p2p.binance.com'
                          },
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
          const SizedBox(height: 24),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '1.0.0';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'v$version',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static const String _contactEmail = 'info@giftera-store.com';

  Future<void> _openContactEmail(BuildContext context) async {
    const subject = 'Contacto desde Dólar Argentina';
    const body = 'Hola,\n\nLes escribo desde la app Dólar Argentina.\n\n'
        '[Escriba aquí su consulta o tema de interés]\n\n'
        'Saludos cordiales,';
    // Codificar con %20 para espacios (algunos clientes muestran + literal si usamos queryParameters)
    final query =
        'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    final uri = Uri.parse('mailto:$_contactEmail?$query');

    bool opened = false;
    try {
      if (await canLaunchUrl(uri)) {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      opened = false;
    }

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo abrir el correo. Asegurate de tener una app de correo instalada (Gmail, Outlook, etc.). Podés escribir a $_contactEmail',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
                        content: Text(
                            'No se pudo abrir el enlace: ${source['url']}'),
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
