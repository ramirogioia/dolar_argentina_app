import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/models/dollar_rate.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/models/dollar_snapshot.dart';
import '../../../services/version_checker.dart';
import '../../../widgets/update_dialogs.dart';
import '../../settings/providers/settings_providers.dart';
import '../providers/dollar_providers.dart';
import '../widgets/ad_banner.dart';
import '../widgets/dollar_row.dart';
import '../widgets/home_header.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _updateChecked = false;

  @override
  void initState() {
    super.initState();
    // Verificar actualización inmediatamente cuando se monta el HomePage
    // Esto se ejecuta mientras el splash nativo todavía está visible
    _verificarActualizacion();
  }

  Future<void> _verificarActualizacion() async {
    if (_updateChecked) return; // Evitar múltiples verificaciones
    _updateChecked = true;

    try {
      // Esperar un poco para que el splash nativo termine de mostrarse
      await Future.delayed(const Duration(milliseconds: 300));

      print('🔍 [HOME] Iniciando verificación de actualización...');
      final updateInfo = await VersionChecker.verificarActualizacion();

      print('🔍 [HOME] updateInfo recibido: ${updateInfo != null ? "NO NULL" : "NULL"}');
      if (updateInfo != null) {
        print('🔍 [HOME] Tipo de actualización: ${updateInfo.type}');
      }

      if (mounted && updateInfo != null) {
        if (updateInfo.type == UpdateType.force) {
          print('🔍 [HOME] Mostrando FORCE UPDATE');
          mostrarDialogoForceUpdate(context, updateInfo);
        } else if (updateInfo.type == UpdateType.kind) {
          print('🔍 [HOME] KIND UPDATE detectado, mostrando diálogo...');
          // Esperar un poco más para que la UI esté lista
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              mostrarDialogoKindUpdate(context, updateInfo);
            }
          });
        }
      }
    } catch (e, stackTrace) {
      print('❌ [HOME] Error verificando actualización: $e');
      print('❌ [HOME] Stack trace: $stackTrace');
      // En caso de error, NO bloquear la app
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(dollarSnapshotProvider);

    return Scaffold(
      body: Stack(
        children: [
          snapshotAsync.when(
            data: (snapshot) => RefreshIndicator(
              onRefresh: () async {
                // Forzar refresh inmediato de ambos providers para obtener datos nuevos del backend
                await Future.wait([
                  ref.refresh(dollarSnapshotProvider.future),
                  ref.refresh(fullJsonDataProvider.future),
                ]);
              },
              color: AppTheme.primaryBlue,
              child: _buildContent(context, ref, snapshot),
            ),
            loading: () => Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            ),
            error: (error, stack) => _buildErrorState(context, ref, error),
          ),
          // Selector de idioma: "ES" / "EN" arriba a la izquierda
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: const _LanguageSelector(),
          ),
          // Pill vertical con botones flotantes en la esquina superior derecha
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2C2C2C).withOpacity(0.9)
                    : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3C3C3C)
                      : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    onPressed: () => context.push('/settings'),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  Container(
                    width: 24,
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.calculate_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    onPressed: () => context.push('/calculator'),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _isNetworkError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('timeout') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('service_not_available') ||
        msg.contains('no internet') ||
        msg.contains('connection refused');
  }

  static Widget _buildErrorState(
      BuildContext context, WidgetRef ref, Object error) {
    final l10n = AppLocalizations.of(context);
    final isNetwork = _isNetworkError(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetwork ? Icons.wifi_off_rounded : Icons.error_outline,
              size: 64,
              color: isNetwork
                  ? Theme.of(context).colorScheme.primary
                  : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              isNetwork ? l10n.noConnection : l10n.errorLoadingData,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isNetwork ? l10n.errorSubtitle : l10n.errorSubtitleGeneric,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),
            if (!isNetwork) ...[
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.8),
                    ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(dollarSnapshotProvider),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, DollarSnapshot snapshot) {
    // Obtener el orden y la visibilidad configurados
    final order = ref.watch(dollarTypeOrderProvider);
    final visibility = ref.watch(dollarTypeVisibilityProvider);

    // Crear un mapa para acceso rápido
    final ratesMap = {for (var rate in snapshot.rates) rate.type: rate};

    // Filtrar y ordenar según la configuración
    final visibleRates = <DollarRate>[];
    for (final type in order) {
      if (visibility[type] ?? true) {
        final rate = ratesMap[type];
        if (rate != null) {
          visibleRates.add(rate);
        }
      }
    }

    return Stack(
      children: [
        // Contenido scrolleable con padding bottom para el banner fijo
        Scrollbar(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: HomeHeader(
                  updatedAt: snapshot.updatedAt,
                  lastMeasurementAt: snapshot.lastMeasurementAt,
                ),
              ),
              // Lista de cards con scroll (solo los visibles)
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final rate = visibleRates[index];
                  return DollarRow(rate: rate);
                }, childCount: visibleRates.length),
              ),
              // Línea divisoria y texto informativo sobre las fuentes
              SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    // Línea divisoria (igual que en el header)
                    Builder(
                      builder: (context) {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        return Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.1),
                                      Colors.white.withOpacity(0.15),
                                      Colors.white.withOpacity(0.1),
                                      Colors.transparent,
                                    ]
                                  : [
                                      Colors.transparent,
                                      const Color(0xFF2196F3).withOpacity(0.2),
                                      const Color(0xFF2196F3).withOpacity(0.4),
                                      const Color(0xFF2196F3).withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : const Color(0xFF2196F3).withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 8, bottom: 12),
                      child: Text(
                        AppLocalizations.of(context).dataSourceFooter,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.2,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Espacio para el banner fijo: adaptativo según dispositivo
              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    // Detectar si es tablet (ancho >= 600px)
                    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
                    // Leaderboard (90px) para tablets, Large Banner (100px) para phones
                    final bannerHeight = isTablet ? 90.0 : 100.0;
                    // Altura total: banner + márgenes verticales (8px arriba + 8px abajo = 16px)
                    return SizedBox(
                      height: bannerHeight + 16 + 8, // banner + márgenes + espacio superior
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Banner fijo en la parte inferior con espacio celeste arriba
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pequeño espacio entre contenido y banner
              Container(
                height: 8,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              // Banner de publicidad
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: const AdBanner(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Selector de idioma: muestra "ES" o "EN" arriba a la izquierda; al tocar, opción para cambiar.
class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector();

  static const String _flagEs = '🇪🇸';
  static const String _flagEn = '🇬🇧';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final label = (current == 'en') ? '$_flagEn EN' : '$_flagEs ES';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2C).withOpacity(0.9)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF3C3C3C)
              : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        tooltip: '',
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        onSelected: (value) {
          ref.read(localeProvider.notifier).setLocale(value);
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'es',
            child: Text(
              '$_flagEs ES',
              style: TextStyle(
                fontWeight: current != 'en' ? FontWeight.w600 : FontWeight.normal,
                color: current != 'en'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          PopupMenuItem(
            value: 'en',
            child: Text(
              '$_flagEn EN',
              style: TextStyle(
                fontWeight: current == 'en' ? FontWeight.w600 : FontWeight.normal,
                color: current == 'en'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
