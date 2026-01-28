import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/models/dollar_rate.dart';
import '../../../domain/models/dollar_snapshot.dart';
import '../../settings/providers/settings_providers.dart';
import '../providers/dollar_providers.dart';
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
                ref.invalidate(dollarSnapshotProvider);
                await ref.read(dollarSnapshotProvider.future);
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
              // Espacio para el banner fijo + espacio celeste visible
              SliverToBoxAdapter(
                child: Container(
                  height:
                      148, // 100 (banner) + 32 (margen banner) + 16 (espacio celeste visible)
                  color: Colors
                      .transparent, // Transparente para que se vea el fondo celeste
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
                child: const _AdPlaceholder(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdPlaceholder extends StatelessWidget {
  const _AdPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2C)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF3C3C3C)
              : Colors.grey[300]!,
        ),
      ),
      child: Center(
        child: Text(
          'Publicidad (AdMob)',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
