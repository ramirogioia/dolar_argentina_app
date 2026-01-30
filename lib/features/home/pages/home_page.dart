import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/models/dollar_rate.dart';
import '../../../domain/models/dollar_snapshot.dart';
import '../../settings/providers/settings_providers.dart';
import '../providers/dollar_providers.dart';
import '../widgets/ad_banner.dart';
import '../widgets/dollar_row.dart';
import '../widgets/home_header.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(dollarSnapshotProvider);

    return Scaffold(
      body: Stack(
        children: [
          snapshotAsync.when(
            data: (snapshot) => RefreshIndicator(
              onRefresh: () async {
                // Invalidar ambos providers para forzar la actualización desde GitHub
                ref.invalidate(dollarSnapshotProvider);
                ref.invalidate(fullJsonDataProvider);
                // Esperar a que ambos se actualicen
                await Future.wait([
                  ref.read(dollarSnapshotProvider.future),
                  ref.read(fullJsonDataProvider.future),
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
          // Botón de configuración flotante en la esquina superior derecha
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => context.push('/settings'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
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
              isNetwork ? 'Sin conexión' : 'Error al cargar datos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isNetwork
                  ? 'Revisá que tengas WiFi o datos móviles activos y tocá Reintentar.'
                  : 'No se pudieron cargar las cotizaciones.',
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
              label: const Text('Reintentar'),
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
                    // Texto informativo adaptado para una línea
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 8, bottom: 12),
                      child: Text(
                        'Datos obtenidos directamente de las entidades oficiales.',
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
              // Espacio para el banner fijo (Large Banner 100px + márgenes): leyenda visible sin tapar
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 122,
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
