import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/settings_providers.dart';
import '../../../services/fcm_service.dart';
import '../../../services/review_service.dart';
import '../../home/widgets/ad_banner.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
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
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              children: [
          _buildSectionHeader(l10n.sectionAppearance),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              secondary: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              title: Text(
                l10n.darkMode,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                l10n.darkModeSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.9),
                ),
              ),
              value: isDarkMode,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).setThemeMode(
                      value ? 'dark' : 'light',
                    );
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.sectionNotifications),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  secondary: Icon(
                    ref.watch(notificationsEnabledProvider)
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                  title: Text(
                    l10n.pushNotifications,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    l10n.pushNotificationsSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.9),
                    ),
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
                FutureBuilder<AuthorizationStatus>(
                  future: _notificationPermissionFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData ||
                        snapshot.data != AuthorizationStatus.denied) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Icon(
                        Icons.settings_suggest_rounded,
                        size: 22,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        Platform.isIOS
                            ? l10n.openSettingsIos
                            : l10n.openSettings,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      subtitle: Text(
                        l10n.notificationsDisabledSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.9),
                        ),
                      ),
                      onTap: () => AppSettings.openAppSettings(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.sectionCustomization),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            child: _buildExpansionTile(
              context,
              icon: Icons.tune_rounded,
              title: l10n.visibleDollarTypes,
              subtitle: l10n.visibleDollarTypesSubtitle,
              child: Builder(
                builder: (context) {
                  final order = ref.watch(dollarTypeOrderProvider);
                  final visibility = ref.watch(dollarTypeVisibilityProvider);
                  return ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: (oldIndex, newIndex) {
                      ref.read(dollarTypeOrderProvider.notifier).reorder(oldIndex, newIndex);
                    },
                    children: order.map((type) {
                      final isVisible = visibility[type] ?? true;
                      return ListTile(
                        key: ValueKey(type),
                        leading: Icon(
                          Icons.drag_handle_rounded,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          size: 22,
                        ),
                        title: Text(l10n.dollarTypeName(type)),
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
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.sectionSupport),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionTile(
                  context,
                  icon: Icons.star_rounded,
                  title: l10n.rateUs,
                  subtitle: l10n.rateUsSubtitle,
                  onTap: () => ReviewService.requestReview(),
                ),
                Divider(
                  height: 1,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  indent: 56,
                ),
                _buildActionTile(
                  context,
                  icon: Icons.mail_outline_rounded,
                  title: l10n.contactAndAds,
                  subtitle: l10n.contactAndAdsSubtitle,
                  onTap: () => _openContactEmail(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.sectionInformation),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            child: _buildExpansionTile(
              context,
              icon: Icons.info_outline_rounded,
              title: l10n.appInfo,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection(context, l10n.functionalityTitle, l10n.functionalityContent, Icons.currency_exchange_rounded),
                    const SizedBox(height: 16),
                    _buildInfoSection(context, l10n.variationMarkersTitle, l10n.variationMarkersContent, Icons.trending_up_rounded),
                    const SizedBox(height: 16),
                    _buildInfoSection(context, l10n.availableOptionsTitle, l10n.availableOptionsContent, Icons.tune_rounded),
                    const SizedBox(height: 16),
                    _buildInfoSection(context, l10n.dataSourcesTitle, l10n.dataSourcesContent, Icons.cloud_done_rounded),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            isDark: isDark,
            child: _buildExpansionTile(
              context,
              icon: Icons.link_rounded,
              title: l10n.informationSources,
              subtitle: l10n.informationSourcesSubtitle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSourceSection(context, l10n.officialDollar, [
                      {'nombre': 'Banco Nación', 'url': 'https://www.bna.com.ar/Personas'},
                      {'nombre': 'BBVA Argentina', 'url': 'https://www.bbva.com.ar/personas/productos/inversiones/cotizacion-moneda-extranjera.html'},
                      {'nombre': 'Banco Supervielle', 'url': 'https://www.supervielle.com.ar/personas/inversiones/moneda-extranjera/compra-y-venta'},
                      {'nombre': 'Banco Patagonia', 'url': 'https://ebankpersonas.bancopatagonia.com.ar/eBanking/usuarios/cotizacionMonedaExtranjera.htm'},
                      {'nombre': 'Banco Provincia', 'url': 'https://www.bancoprovincia.com.ar/productos/inversiones/dolares_bip/dolares_bip_info_gral'},
                      {'nombre': 'Banco Ciudad', 'url': 'https://bancociudad.com.ar/institucional/'},
                      {'nombre': 'Banco Hipotecario', 'url': 'https://www.hipotecario.com.ar/buho-one/inversiones/cotizaciones/'},
                      {'nombre': 'ICBC Argentina', 'url': 'https://www.icbc.com.ar/personas/start'},
                    ], Icons.account_balance),
                    const SizedBox(height: 24),
                    _buildSourceSection(context, l10n.cryptoDollar, [
                      {'nombre': 'Binance', 'url': 'https://p2p.binance.com'},
                      {'nombre': 'KuCoin', 'url': 'https://www.kucoin.com'},
                      {'nombre': 'Bybit', 'url': 'https://www.bybit.com'},
                      {'nombre': 'OKX', 'url': 'https://www.okx.com'},
                      {'nombre': 'Bitget', 'url': 'https://www.bitget.com'},
                    ], Icons.currency_bitcoin),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '1.0.0';
              return Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'v$version',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ),
              );
            },
          ),
          // Espacio para el banner fijo (misma lógica que Home)
          Builder(
            builder: (context) {
              final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
              final bannerHeight = isTablet ? 90.0 : 100.0;
              return SizedBox(height: bannerHeight + 16 + 8);
            },
          ),
        ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 8,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: AdBanner(
                    customAdUnitId: Platform.isIOS
                        ? adMobSettingsBannerUnitIdIos
                        : adMobSettingsBannerUnitIdAndroid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.85),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      childrenPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.9),
                ),
              ),
            )
          : null,
      trailing: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
      ),
      children: [child],
    );
  }

  static const String _contactEmail = 'info@giftera-store.com';

  Future<void> _openContactEmail(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final subject = l10n.contactEmailSubject;
    final body = l10n.contactEmailBody;
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
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.contactEmailError(_contactEmail)),
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
                    final l10n = AppLocalizations.of(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.couldNotOpenLink(source['url']!)),
                      ),
                    );
                  }
                }
              },
              child: Row(
                children: [
                  Icon(
                    Icons.open_in_new_rounded,
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
        }),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _SettingsCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppTheme.primaryBlue).withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: isDark ? 12 : 16,
            offset: const Offset(0, 4),
            spreadRadius: isDark ? 0 : -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}
