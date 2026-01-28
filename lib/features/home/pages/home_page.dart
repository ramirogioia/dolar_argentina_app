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
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar datos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(dollarSnapshotProvider);
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
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
                child: HomeHeader(updatedAt: snapshot.updatedAt),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
              // Espacio para el banner fijo
              // Altura del Large Banner (100px) + espacio celeste arriba (16px) = 116px
              // El banner tiene su propio margen interno
              SliverToBoxAdapter(
                child: SizedBox(
                  height:
                      116, // 100 (Large Banner) + 16 (espacio celeste arriba)
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
              // Espacio celeste visible entre la última tarjeta y el banner
              Container(
                height: 16,
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
