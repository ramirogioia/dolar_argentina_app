import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/models/historical_rate.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/historicos_providers.dart';
import '../../home/widgets/ad_banner.dart';

// ─── Tipos de dólar disponibles en el histórico ──────────────────────────────

enum HistoricalDollarType { blue, oficial, cripto }

/// Color de línea del histórico USDT/ARS (P2P), coherente con “cripto” en la app.
const Color _historicoCriptoLineColor = Color(0xFFE6B00C);

// ─── Rangos de tiempo ─────────────────────────────────────────────────────────

enum TimeRange {
  week7,
  /// Solo para histórico Cripto (pocos datos).
  days15,
  month1,
  /// Solo para histórico Cripto (~2 meses).
  months2,
  month3,
  year1,
  year5,
  all;

  String label(AppLocalizations l10n) {
    switch (this) {
      case TimeRange.week7:
        return l10n.range7d;
      case TimeRange.days15:
        return l10n.range15d;
      case TimeRange.month1:
        return l10n.range1m;
      case TimeRange.months2:
        return l10n.range2m;
      case TimeRange.month3:
        return l10n.range3m;
      case TimeRange.year1:
        return l10n.range1y;
      case TimeRange.year5:
        return l10n.range5y;
      case TimeRange.all:
        return l10n.rangeAll;
    }
  }

  Duration? get duration {
    switch (this) {
      case TimeRange.week7:
        return const Duration(days: 7);
      case TimeRange.days15:
        return const Duration(days: 15);
      case TimeRange.month1:
        return const Duration(days: 30);
      case TimeRange.months2:
        return const Duration(days: 60);
      case TimeRange.month3:
        return const Duration(days: 91);
      case TimeRange.year1:
        return const Duration(days: 365);
      case TimeRange.year5:
        return const Duration(days: 1825);
      case TimeRange.all:
        return null;
    }
  }
}

/// Blue / Oficial: series largas (años).
const List<TimeRange> _timeRangesStandard = [
  TimeRange.week7,
  TimeRange.month1,
  TimeRange.month3,
  TimeRange.year1,
  TimeRange.year5,
  TimeRange.all,
];

/// Cripto: pocos meses de datos.
const List<TimeRange> _timeRangesCripto = [
  TimeRange.week7,
  TimeRange.days15,
  TimeRange.month1,
  TimeRange.months2,
  TimeRange.month3,
  TimeRange.all,
];

// ─── Página principal ─────────────────────────────────────────────────────────

class HistoricosPage extends ConsumerStatefulWidget {
  final HistoricalDollarType? initialType;

  const HistoricosPage({super.key, this.initialType});

  @override
  ConsumerState<HistoricosPage> createState() => _HistoricosPageState();
}

class _HistoricosPageState extends ConsumerState<HistoricosPage> {
  late HistoricalDollarType _selectedType;
  TimeRange _selectedRange = TimeRange.month1;

  static TimeRange _coerceRangeForType(
    HistoricalDollarType type,
    TimeRange r,
  ) {
    final valid = type == HistoricalDollarType.cripto
        ? _timeRangesCripto
        : _timeRangesStandard;
    return valid.contains(r) ? r : TimeRange.month1;
  }

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? HistoricalDollarType.blue;
    _selectedRange = _coerceRangeForType(_selectedType, _selectedRange);
  }

  @override
  void didUpdateWidget(HistoricosPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialType != widget.initialType &&
        widget.initialType != null) {
      setState(() {
        _selectedType = widget.initialType!;
        _selectedRange = _coerceRangeForType(_selectedType, _selectedRange);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshotAsync = ref.watch(historicalSnapshotProvider);
    final binanceAsync = ref.watch(historicalBinanceSnapshotProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.historicos,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : AppTheme.primaryBlue.withOpacity(0.15),
          ),
        ),
      ),
      body: Stack(
        children: [
          snapshotAsync.when(
            data: (snapshot) =>
                _buildContent(context, snapshot, binanceAsync, l10n),
            loading: () => const _LoadingState(),
            error: (err, _) => _ErrorState(
              onRetry: () => ref.invalidate(historicalSnapshotProvider),
              l10n: l10n,
            ),
          ),
          // Banner de publicidad fijo en la parte inferior
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
                    customAdUnitId: kReleaseMode
                        ? (Platform.isAndroid
                            ? adMobHistoricosBannerUnitIdAndroid
                            : adMobHistoricosBannerUnitIdIos)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    HistoricalSnapshot snapshot,
    AsyncValue<HistoricalSnapshot> binanceAsync,
    AppLocalizations l10n,
  ) {
    final blueFiltered = _filterSerie(snapshot.serie);

    final Widget chartSection;
    if (_selectedType == HistoricalDollarType.cripto) {
      chartSection = binanceAsync.when(
        loading: () => const _LoadingState(),
        error: (_, __) => _ErrorState(
          onRetry: () =>
              ref.invalidate(historicalBinanceSnapshotProvider),
          l10n: l10n,
        ),
        data: (binanceSnap) {
          final filtered = _filterSerie(binanceSnap.serie);
          if (filtered.isEmpty) {
            return _EmptyState(l10n: l10n);
          }
          return _ChartArea(
            serie: filtered,
            type: _selectedType,
            range: _selectedRange,
            l10n: l10n,
            footerText: l10n.dataSourceFooter,
          );
        },
      );
    } else {
      chartSection = blueFiltered.isEmpty
          ? _EmptyState(l10n: l10n)
          : _ChartArea(
              serie: blueFiltered,
              type: _selectedType,
              range: _selectedRange,
              l10n: l10n,
              footerText: l10n.dataSourceFooter,
            );
    }

    return Column(
      children: [
        // ── Filtro tipo de dólar ─────────────────────────────────────────
        _DollarTypeFilter(
          selected: _selectedType,
          onChanged: (t) => setState(() {
            _selectedType = t;
            _selectedRange = _coerceRangeForType(t, _selectedRange);
          }),
          l10n: l10n,
        ),
        // ── Filtro rango de tiempo ───────────────────────────────────────
        _TimeRangeFilter(
          ranges: _selectedType == HistoricalDollarType.cripto
              ? _timeRangesCripto
              : _timeRangesStandard,
          selected: _selectedRange,
          onChanged: (r) => setState(() => _selectedRange = r),
          l10n: l10n,
        ),
        // ── Gráfico ─────────────────────────────────────────────────────
        Expanded(child: chartSection),
        // Espacio para el ad banner
        const SizedBox(height: 116),
      ],
    );
  }

  List<HistoricalRate> _filterSerie(List<HistoricalRate> all) {
    final duration = _selectedRange.duration;
    if (duration == null) return all;
    final cutoff = DateTime.now().subtract(duration);
    return all.where((r) => r.date.isAfter(cutoff)).toList();
  }
}

// ─── Filtro tipo de dólar ─────────────────────────────────────────────────────

class _DollarTypeFilter extends StatelessWidget {
  final HistoricalDollarType selected;
  final ValueChanged<HistoricalDollarType> onChanged;
  final AppLocalizations l10n;

  const _DollarTypeFilter({
    required this.selected,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final types = HistoricalDollarType.values;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          for (var i = 0; i < types.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _buildTypeChip(
                context,
                types[i],
                isDark: isDark,
                primary: primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _label(HistoricalDollarType type) {
    switch (type) {
      case HistoricalDollarType.blue:
        return l10n.historicosBlue;
      case HistoricalDollarType.oficial:
        return l10n.historicosOficial;
      case HistoricalDollarType.cripto:
        return l10n.historicosCripto;
    }
  }

  Widget _buildTypeChip(
    BuildContext context,
    HistoricalDollarType type, {
    required bool isDark,
    required Color primary,
  }) {
    final isSelected = selected == type;
    final label = _label(type);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(type),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? primary
                  : isDark
                      ? const Color(0xFF2C2C2C)
                      : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? primary
                    : isDark
                        ? const Color(0xFF3C3C3C)
                        : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.white70
                        : Colors.grey.shade700,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Filtro rango de tiempo ───────────────────────────────────────────────────

class _TimeRangeFilter extends StatelessWidget {
  final List<TimeRange> ranges;
  final TimeRange selected;
  final ValueChanged<TimeRange> onChanged;
  final AppLocalizations l10n;

  const _TimeRangeFilter({
    required this.ranges,
    required this.selected,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF3C3C3C) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: ranges.map((range) {
            final isSelected = selected == range;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(range),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.all(3),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    range.label(l10n),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isDark
                              ? Colors.white54
                              : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Área del gráfico ─────────────────────────────────────────────────────────

class _ChartArea extends StatefulWidget {
  final List<HistoricalRate> serie;
  final HistoricalDollarType type;
  final TimeRange range;
  final AppLocalizations l10n;
  final String footerText;

  const _ChartArea({
    required this.serie,
    required this.type,
    required this.range,
    required this.l10n,
    required this.footerText,
  });

  @override
  State<_ChartArea> createState() => _ChartAreaState();
}

class _ChartAreaState extends State<_ChartArea> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final values = _getValues();
    if (values.isEmpty) return _EmptyState(l10n: widget.l10n);

    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final rangeY = maxY - minY;
    final padY = rangeY == 0 ? 10.0 : rangeY * 0.05;
    final bottomY = (minY - padY).clamp(0.0, double.infinity);
    final topY = maxY + padY;

    final spots = <FlSpot>[];
    for (var i = 0; i < widget.serie.length; i++) {
      final v = switch (widget.type) {
        HistoricalDollarType.blue => widget.serie[i].blueVenta,
        HistoricalDollarType.oficial => widget.serie[i].oficialVenta,
        HistoricalDollarType.cripto => widget.serie[i].binanceVenta,
      };
      if (v != null) {
        spots.add(FlSpot(i.toDouble(), v));
      }
    }
    if (spots.isEmpty) return _EmptyState(l10n: widget.l10n);

    final dataMinX = spots.first.x;
    final dataMaxX = spots.last.x;
    final spanData = dataMaxX - dataMinX;
    // Margen horizontal en espacio de índices: 4 % del span, mín. 0.5 puntos.
    // Sin tope superior → series largas (años) siguen teniendo ~12–15 px físicos de margen.
    final padX = spanData <= 0 ? 0.5 : (spanData * 0.04).clamp(0.5, double.infinity);
    final chartMinX = dataMinX - padX;
    final chartMaxX = dataMaxX + padX;

    final lineColor = switch (widget.type) {
      HistoricalDollarType.blue => AppTheme.primaryBlue,
      HistoricalDollarType.oficial => const Color(0xFF1A8B73),
      HistoricalDollarType.cripto => _historicoCriptoLineColor,
    };

    // Calcular estadísticas para la tarjeta de resumen
    final lastValue = values.last;
    final firstValue = values.first;
    final changeAbs = lastValue - firstValue;
    final changePct = firstValue != 0 ? (changeAbs / firstValue) * 100 : 0.0;
    final isPositive = changeAbs >= 0;

    final todoSingleCalendarYear = widget.range == TimeRange.all &&
        widget.serie.isNotEmpty &&
        widget.serie.first.date.year == widget.serie.last.date.year;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // ── Tarjeta de resumen ─────────────────────────────────────────
          _SummaryCard(
            currentValue: lastValue,
            changeAbs: changeAbs,
            changePct: changePct.toDouble(),
            isPositive: isPositive,
            type: widget.type,
            l10n: widget.l10n,
            isDark: isDark,
            lineColor: lineColor,
          ),
          const SizedBox(height: 12),
          // ── Gráfico ────────────────────────────────────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 4 etiquetas fijas repartidas sobre el tramo real de la serie.
                // interval:1 → fl_chart pregunta por cada índice entero;
                // el Set decide cuáles se muestran.
                final labelIndices = _evenlySpacedIndicesInclusive(
                  dataMinX.round(),
                  dataMaxX.round(),
                  4,
                );
                final chart = LineChart(
                  duration: const Duration(milliseconds: 300),
                  LineChartData(
                minX: chartMinX,
                maxX: chartMaxX,
                minY: bottomY,
                maxY: topY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _gridInterval(minY, maxY),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 58,
                      getTitlesWidget: (value, meta) =>
                          _leftTitle(value, meta, isDark, bottomY, topY),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: !todoSingleCalendarYear,
                      reservedSize: todoSingleCalendarYear ? 8 : 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final roundedIdx = value.round();
                        if (!labelIndices.contains(roundedIdx)) {
                          return const SizedBox.shrink();
                        }
                        return _bottomTitle(
                          value,
                          widget.serie,
                          widget.range,
                          isDark,
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                        reservedSize: 20,
                      )),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipColor: (_) => isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.white,
                    tooltipRoundedRadius: 10,
                    tooltipBorder: BorderSide(
                      color: lineColor.withOpacity(0.4),
                      width: 1,
                    ),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        if (idx < 0 || idx >= widget.serie.length) {
                          return null;
                        }
                        final rate = widget.serie[idx];
                        final dateStr =
                            DateFormat('dd/MM/yyyy').format(rate.date);
                        final priceStr = _formatPrice(spot.y);
                        return LineTooltipItem(
                          '$dateStr\n',
                          TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            TextSpan(
                              text: priceStr,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: lineColor,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((_) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: lineColor.withOpacity(0.4),
                          strokeWidth: 1.5,
                          dashArray: [4, 4],
                        ),
                        FlDotData(
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                            radius: 5,
                            color: lineColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  handleBuiltInTouches: true,
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: widget.serie.length > 30,
                    curveSmoothness: 0.25,
                    color: lineColor,
                    barWidth: widget.serie.length > 365 ? 1.2 : 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          lineColor.withOpacity(0.25),
                          lineColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    shadow: Shadow(
                      color: lineColor.withOpacity(0.15),
                      blurRadius: 6,
                    ),
                  ),
                ],
              ),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: chart),
                    if (todoSingleCalendarYear)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${widget.serie.first.date.year}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // ── Fuente de datos ────────────────────────────────────────────
          Text(
            widget.footerText,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<double> _getValues() {
    return widget.serie
        .map((r) => switch (widget.type) {
              HistoricalDollarType.blue => r.blueVenta,
              HistoricalDollarType.oficial => r.oficialVenta,
              HistoricalDollarType.cripto => r.binanceVenta,
            })
        .whereType<double>()
        .toList();
  }

  static String _formatPrice(double v) {
    if (v >= 1000) {
      return '\$${NumberFormat('#,##0', 'es_AR').format(v)}';
    }
    return '\$${NumberFormat('#,##0.00', 'es_AR').format(v)}';
  }

  static double _gridInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 10;
    if (range <= 5) return 1;
    if (range <= 50) return 10;
    if (range <= 500) return 100;
    if (range <= 5000) return 1000;
    if (range <= 50000) return 10000;
    return 100000;
  }

  /// 4 índices repartidos uniformemente entre [minI] y [maxI] (ambos inclusive).
  static Set<int> _evenlySpacedIndicesInclusive(
    int minI,
    int maxI,
    int targetCount,
  ) {
    final out = <int>{};
    if (maxI < minI) return out;
    final span = maxI - minI;
    if (span == 0) {
      out.add(minI);
      return out;
    }
    final n = targetCount.clamp(2, span + 1);
    for (var k = 0; k < n; k++) {
      final idx = minI + ((k * span) / (n - 1)).round();
      out.add(idx.clamp(minI, maxI));
    }
    return out;
  }

  static Widget _leftTitle(
    double value,
    TitleMeta meta,
    bool isDark,
    double chartMin,
    double chartMax,
  ) {
    // Ocultar etiquetas que caen fuera del área visible del gráfico
    if (value < chartMin || value > chartMax) return const SizedBox.shrink();
    // Ocultar min y max exactos que fl_chart genera automáticamente en los extremos
    if (value == meta.min || value == meta.max) return const SizedBox.shrink();
    final label = '\$${NumberFormat('#,##0', 'es_AR').format(value)}';
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isDark ? Colors.white38 : Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  /// Formatea la etiqueta del eje X según la amplitud real de la serie mostrada.
  /// [isFirst] / [isLast] controlan la alineación para que el texto no quede
  /// cortado contra los bordes del gráfico.
  static Widget _bottomTitle(
    double value,
    List<HistoricalRate> serie,
    TimeRange range,
    bool isDark,
  ) {
    final idx = value.round();
    if (idx < 0 || idx >= serie.length) return const SizedBox.shrink();

    final first = serie.first.date;
    final last = serie.last.date;
    final spanDays = last.difference(first).inDays.abs();
    final date = serie[idx].date;

    // Formato según la amplitud real del tramo visible:
    //  ≤ 90 días  → "d MMM"   (p. ej. "24 mar")
    //  ≤ 730 días → "MMM yy"  (p. ej. "mar 26")
    //  > 730 días → "yyyy"    (p. ej. "2023")
    final String label;
    if (spanDays <= 90) {
      label = DateFormat('d MMM', 'es').format(date);
    } else if (spanDays <= 730) {
      label = DateFormat('MMM yy', 'es').format(date);
    } else {
      label = DateFormat('yyyy', 'es').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isDark ? Colors.white38 : Colors.grey.shade500,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

// ─── Tarjeta de resumen ───────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double currentValue;
  final double changeAbs;
  final double changePct;
  final bool isPositive;
  final HistoricalDollarType type;
  final AppLocalizations l10n;
  final bool isDark;
  final Color lineColor;

  const _SummaryCard({
    required this.currentValue,
    required this.changeAbs,
    required this.changePct,
    required this.isPositive,
    required this.type,
    required this.l10n,
    required this.isDark,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final changeColor =
        changeAbs == 0 ? AppTheme.variationNeutral : isPositive ? AppTheme.softRed : AppTheme.softGreen;
    final changeIcon =
        changeAbs == 0 ? Icons.remove : isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: lineColor.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: lineColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (type) {
                    HistoricalDollarType.blue => l10n.historicosBlue,
                    HistoricalDollarType.oficial => l10n.historicosOficial,
                    HistoricalDollarType.cripto => l10n.historicosCripto,
                  },
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatPrice(currentValue),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.historicosChangeLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(changeIcon, size: 14, color: changeColor),
                  const SizedBox(width: 2),
                  Text(
                    _formatChangePct(changePct),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: changeColor,
                    ),
                  ),
                ],
              ),
              Text(
                _formatChangeAbs(changeAbs),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: changeColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatPrice(double v) {
    if (v >= 1000) {
      return '\$${NumberFormat('#,##0', 'es_AR').format(v)}';
    }
    return '\$${NumberFormat('#,##0.00', 'es_AR').format(v)}';
  }

  static String _formatChangeAbs(double v) {
    final sign = v >= 0 ? '+' : '';
    if (v.abs() >= 1000) {
      return '$sign\$${NumberFormat('#,##0', 'es_AR').format(v)}';
    }
    return '$sign\$${NumberFormat('#,##0.00', 'es_AR').format(v)}';
  }

  /// Dos decimales y separador local; evita "0,0 %" en variaciones muy chicas.
  static String _formatChangePct(double pct) {
    return '${NumberFormat('#0.00', 'es_AR').format(pct.abs())}%';
  }
}

// ─── Estados de carga / error / vacío ────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryBlue),
          const SizedBox(height: 16),
          Text(
            'Cargando histórico...',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  const _ErrorState({required this.onRetry, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.errorLoadingData,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.errorSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        l10n.historicosNoData,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white38
              : Colors.grey.shade500,
        ),
      ),
    );
  }
}
