import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/models/dollar_snapshot.dart';
import '../providers/dollar_providers.dart';
import '../widgets/dollar_row.dart';
import '../widgets/home_header.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(dollarSnapshotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: const Color(0xFFE3F2FD), // Celeste suave
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF2196F3)),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE3F2FD), // Celeste suave
      body: snapshotAsync.when(
        data: (snapshot) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dollarSnapshotProvider);
            await ref.read(dollarSnapshotProvider.future);
          },
          color: AppTheme.primaryBlue,
          child: _buildContent(context, snapshot),
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
    );
  }

  Widget _buildContent(BuildContext context, DollarSnapshot snapshot) {
    return Stack(
      children: [
        // Contenido scrolleable con padding bottom para el banner fijo
        CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: HomeHeader(updatedAt: snapshot.updatedAt)),
            // Lista de cards con scroll
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final rate = snapshot.rates[index];
                return DollarRow(rate: rate);
              }, childCount: snapshot.rates.length),
            ),
            // Espacio para el banner fijo
            const SliverToBoxAdapter(child: SizedBox(height: 132)), // 100 (banner) + 32 (margen)
          ],
        ),
        // Banner fijo en la parte inferior
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: const Color(0xFFE3F2FD), // Mismo color de fondo
            child: const _AdPlaceholder(),
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
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Text(
          'Publicidad (AdMob)',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }
}
