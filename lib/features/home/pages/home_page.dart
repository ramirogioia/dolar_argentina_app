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
import '../../../services/review_service.dart';
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
  bool _reviewPromptScheduled = false;

  @override
  void initState() {
    super.initState();
    // Verificar actualización inmediatamente cuando se monta el HomePage
    // Esto se ejecuta mientras el splash nativo todavía está visible
    _verificarActualizacion();
  }

  Future<void> _verificarActualizacion() async {
    if (_updateChecked) return;
    _updateChecked = true;

    try {
      // Esperar 3s para que la app esté completamente cargada antes del check
      await Future.delayed(const Duration(seconds: 3));

      UpdateInfo? updateInfo = await VersionChecker.verificarActualizacion();

      // Reintento si falló (red lenta en arranque)
      if (updateInfo == null && mounted) {
        await Future.delayed(const Duration(seconds: 5));
        updateInfo = await VersionChecker.verificarActualizacion();
      }

      if (!mounted || updateInfo == null) return;

      final info = updateInfo;
      if (info.type == UpdateType.force) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) mostrarDialogoForceUpdate(context, info);
        });
      } else if (info.type == UpdateType.kind) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) mostrarDialogoKindUpdate(context, info);
        });
      }
    } catch (_) {
      // En caso de error, NO bloquear la app
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(dollarSnapshotProvider);
    final l10n = AppLocalizations.of(context);

    // Reseña: cuando home ya tiene datos (4.ª apertura o ≥4 días instalada).
    // ref.listen no notifica si el async ya venía en Data al suscribirse; por eso
    // programamos aquí la primera vez que hay valor + post-frame.
    if (snapshotAsync.hasValue && !_reviewPromptScheduled) {
      _reviewPromptScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          unawaited(ReviewService.showReviewDialogIfNeeded(context));
        });
      });
    }

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
                  ref.refresh(appLinksVariablesProvider.future),
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
          // Pill mismo estilo que idioma: colapsado muestra menú; al tocar, Históricos / Calculadora / Configuración
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: _ToolsMenuPill(
              historicosLabel: l10n.historicos,
              calculatorLabel: l10n.calculator,
              settingsLabel: l10n.settings,
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
                  appLinks:
                      ref.watch(appLinksVariablesProvider).valueOrNull,
                ),
              ),
              // Lista de cards con scroll (solo los visibles)
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final rate = visibleRates[index];
                  return DollarRow(
                    rate: rate,
                  );
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

/// Mismo estilo que [_LanguageSelector]: pill horizontal; al tocar se despliega el menú.
class _ToolsMenuPill extends StatelessWidget {
  final String historicosLabel;
  final String calculatorLabel;
  final String settingsLabel;

  const _ToolsMenuPill({
    required this.historicosLabel,
    required this.calculatorLabel,
    required this.settingsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
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
          child: Icon(
            Icons.menu_rounded,
            size: 22,
            color: primary,
          ),
        ),
        onSelected: (value) {
          if (value == 'historicos') {
            context.push('/historicos');
          } else if (value == 'calculator') {
            context.push('/calculator');
          } else if (value == 'settings') {
            context.push('/settings');
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'historicos',
            child: Row(
              children: [
                Icon(Icons.show_chart_rounded, size: 20, color: primary),
                const SizedBox(width: 12),
                Text(historicosLabel),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'calculator',
            child: Row(
              children: [
                Icon(Icons.calculate_outlined, size: 20, color: primary),
                const SizedBox(width: 12),
                Text(calculatorLabel),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings_outlined, size: 20, color: primary),
                const SizedBox(width: 12),
                Text(settingsLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opciones de idioma: ES, EN (USA), IT, GER
class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector();

  static const String _flagEs = '🇪🇸';
  static const String _flagEn = '🇺🇸'; // USA
  static const String _flagIt = '🇮🇹';
  static const String _flagDe = '🇩🇪';

  static const List<({String code, String flag, String label})> _options = [
    (code: 'es', flag: _flagEs, label: 'ES'),
    (code: 'en', flag: _flagEn, label: 'EN'),
    (code: 'it', flag: _flagIt, label: 'IT'),
    (code: 'de', flag: _flagDe, label: 'GER'),
  ];

  /// Idioma de UI soportado más cercano al [locale] del sistema (p. ej. en_US → en).
  static String _languageCodeFromPlatform(Locale locale) {
    final c = locale.languageCode.toLowerCase();
    for (final o in _options) {
      if (o.code == c) return c;
    }
    return 'es';
  }

  static ({String code, String flag, String label}) _optionForCode(String code) {
    return _options.firstWhere((o) => o.code == code, orElse: () => _options.first);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    final platformLocale = Localizations.maybeLocaleOf(context) ??
        View.of(context).platformDispatcher.locale;
    // '' guardado = seguir dispositivo; antes el pill caía en ES por orElse aunque la UI era en inglés.
    final effectiveCode = current.isEmpty
        ? _languageCodeFromPlatform(platformLocale)
        : current;
    final displayOption = _optionForCode(effectiveCode);
    final label = current.isEmpty
        ? '🌐 ${displayOption.flag} ${displayOption.label}'
        : '${displayOption.flag} ${displayOption.label}';

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
          PopupMenuItem<String>(
            value: '',
            child: Text(
              l10n.languageSystem,
              style: TextStyle(
                fontWeight: current.isEmpty ? FontWeight.w600 : FontWeight.normal,
                color: current.isEmpty
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          const PopupMenuDivider(),
          for (final opt in _options)
            PopupMenuItem(
              value: opt.code,
              child: Text(
                '${opt.flag} ${opt.label}',
                style: TextStyle(
                  fontWeight: current == opt.code ? FontWeight.w600 : FontWeight.normal,
                  color: current == opt.code
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
