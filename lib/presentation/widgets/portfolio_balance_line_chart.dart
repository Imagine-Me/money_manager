import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';

/// Orange–amber line; readable on dark chart background.
const Color _chartLineAmber = Color(0xFFFFC53D);

/// Muted grey for a comparison series (e.g. previous month).
const Color _chartCompareGrey = Color(0xFF5C5C5C);

/// Line chart for portfolio balance over discrete steps (days or months).
/// Optional [compareSpots] draws behind the main line (same x scale).
class PortfolioBalanceLineChart extends StatelessWidget {
  const PortfolioBalanceLineChart({
    super.key,
    required this.spots,
    required this.minX,
    required this.maxX,
    this.bottomTitleInterval = 1,
    this.formatBottomTitle,
    this.lineColor,
    this.compareSpots,
    this.compareLineColor,
  });

  final List<FlSpot> spots;
  final double minX;
  final double maxX;
  final double bottomTitleInterval;

  /// If set, replaces the default numeric bottom label (e.g. month abbrev).
  final String Function(double x)? formatBottomTitle;

  /// Stroke / fill / dots; defaults to amber portfolio line.
  final Color? lineColor;

  /// Optional second series (e.g. last month), drawn first so it sits behind.
  final List<FlSpot>? compareSpots;

  /// Stroke for [compareSpots]; defaults to [_chartCompareGrey].
  final Color? compareLineColor;

  @override
  Widget build(BuildContext context) {
    final stroke = lineColor ?? _chartLineAmber;
    final compareStroke = compareLineColor ?? _chartCompareGrey;

    if (spots.isEmpty) {
      return const Center(
        child: Text(
          'No data',
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    final lineSpots = spots.length == 1
        ? [spots.first, FlSpot(spots.first.x + 1e-4, spots.first.y)]
        : spots;

    List<FlSpot>? compareLineSpots;
    if (compareSpots != null && compareSpots!.isNotEmpty) {
      final c = compareSpots!;
      compareLineSpots = c.length == 1
          ? [c.first, FlSpot(c.first.x + 1e-4, c.first.y)]
          : List<FlSpot>.from(c);
    }

    var minY = lineSpots.first.y;
    var maxY = lineSpots.first.y;
    for (final s in lineSpots) {
      if (s.y < minY) minY = s.y;
      if (s.y > maxY) maxY = s.y;
    }
    final cmp = compareLineSpots;
    if (cmp != null) {
      for (final s in cmp) {
        if (s.y < minY) minY = s.y;
        if (s.y > maxY) maxY = s.y;
      }
    }
    final pad = (maxY - minY).abs() < 0.01 ? 1.0 : (maxY - minY) * 0.12;
    final chartMinY = minY - pad;
    final chartMaxY = maxY + pad;

    final hasCompare = compareLineSpots != null;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: chartMinY,
        maxY: chartMaxY,
        clipData: const FlClipData.all(),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppTheme.cardElevated,
            getTooltipItems: (touched) => touched
                .map(
                  (s) {
                    final prefix = hasCompare
                        ? (s.barIndex == 0 ? 'Last month: ' : 'This month: ')
                        : '';
                    return LineTooltipItem(
                      '$prefix${CurrencyFormatter.format(s.y)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  },
                )
                .toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                if (value < meta.min || value > meta.max) {
                  return const SizedBox.shrink();
                }
                if ((value - meta.min).abs() < 0.01 ||
                    (value - meta.max).abs() < 0.01) {
                  return Text(
                    CurrencyFormatter.formatCompact(value),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: bottomTitleInterval,
              getTitlesWidget: (value, meta) {
                final v = value.round();
                final maxR = maxX.round();
                if (v < minX.round() || v > maxR) {
                  return const SizedBox.shrink();
                }
                // Day axis: interval often hits both 30 and 31 — keep 31 only.
                if (formatBottomTitle == null && v == 30 && maxR == 31) {
                  return const SizedBox.shrink();
                }
                final text = formatBottomTitle != null
                    ? formatBottomTitle!(value)
                    : '$v';
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          if (cmp != null)
            LineChartBarData(
              spots: cmp,
              isCurved: true,
              curveSmoothness: 0.22,
              preventCurveOverShooting: true,
              color: compareStroke,
              barWidth: 1.75,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          LineChartBarData(
            spots: lineSpots,
            isCurved: true,
            curveSmoothness: 0.22,
            preventCurveOverShooting: true,
            color: stroke,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length <= 14,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: stroke,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  stroke.withValues(alpha: 0.22),
                  stroke.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
