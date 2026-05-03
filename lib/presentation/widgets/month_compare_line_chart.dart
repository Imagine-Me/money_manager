import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/domain/usecases/analytics_engine.dart';

/// Cumulative burn (running total) by day of month: last month (grey) vs this
/// month through today (colored). Flat when there is no spend that day;
/// rises when spend is added. Segment ending on day [d] is green if this
/// month’s cumulative through day [d] is strictly less than last month’s
/// through the same calendar day; red otherwise. Neutral when last month
/// has no such day.
class MonthCompareLineChart extends StatelessWidget {
  const MonthCompareLineChart({super.key, required this.data});

  final MonthOverMonthDailySpend data;

  static const _prevLineColor = Color(0xFF5C5C6A);
  static const _neutralSegmentColor = Color(0xFF8A8A9A);

  static List<double> _cumulative(List<double> daily) {
    final out = <double>[];
    var sum = 0.0;
    for (final v in daily) {
      sum += v;
      out.add(sum);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final prevDaily = data.previousMonthDaily;
    final currDaily = data.currentMonthDaily;
    final daysPrev = prevDaily.length;
    final daysCurr = currDaily.length;
    final today = data.todayDay;

    final cumPrev = _cumulative(prevDaily);
    final cumCurr = _cumulative(currDaily);

    final maxDayAxis = daysPrev > daysCurr ? daysPrev : daysCurr;

    double maxY = 1;
    for (final v in cumPrev) {
      if (v > maxY) maxY = v;
    }
    for (var i = 0; i < today; i++) {
      if (cumCurr[i] > maxY) maxY = cumCurr[i];
    }
    final chartMaxY = maxY == 0 ? 100.0 : maxY * 1.15;

    final prevSpots = List<FlSpot>.generate(
      daysPrev,
      (i) => FlSpot((i + 1).toDouble(), cumPrev[i]),
    );

    final lineBars = <LineChartBarData>[
      if (prevSpots.isNotEmpty)
        LineChartBarData(
          spots: prevSpots,
          isCurved: false,
          color: _prevLineColor,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ..._currentMonthBars(cumPrev, cumCurr, daysPrev, today),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 1,
              maxX: maxDayAxis.toDouble(),
              minY: 0,
              maxY: chartMaxY,
              clipData: const FlClipData.all(),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.cardElevated,
                  getTooltipItems: (touched) {
                    return touched.map((s) {
                      final x = s.x.round();
                      final y = s.y;
                      final isPrev =
                          prevSpots.isNotEmpty && s.barIndex == 0;
                      final label = isPrev
                          ? 'Last month day $x (total so far): ₹${_fmt(y)}'
                          : 'This month day $x (total so far): ₹${_fmt(y)}';
                      return LineTooltipItem(
                        label,
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      );
                    }).toList();
                  },
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
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || (value - meta.max).abs() < 0.01) {
                        return Text(
                          '₹${_compact(value)}',
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
                    reservedSize: 26,
                    interval: _niceXInterval(maxDayAxis),
                    getTitlesWidget: (value, meta) {
                      final d = value.round();
                      if (d < 1 || d > maxDayAxis) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '$d',
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
              lineBarsData: lineBars,
            ),
          ),
        ),
      ],
    );
  }

  /// Segment (d−1)→d: color from cumulative through day [d] vs last month.
  List<LineChartBarData> _currentMonthBars(
    List<double> cumPrev,
    List<double> cumCurr,
    int daysPrev,
    int today,
  ) {
    Color colorForDay(int day) {
      final y = cumCurr[day - 1];
      if (day <= daysPrev) {
        final p = cumPrev[day - 1];
        return y < p ? AppTheme.storeColor : AppTheme.burnColor;
      }
      return _neutralSegmentColor;
    }

    if (today < 1) return [];

    if (today == 1) {
      final c = colorForDay(1);
      return [
        LineChartBarData(
          spots: [
            FlSpot(1, cumCurr[0]),
            FlSpot(1.0001, cumCurr[0]),
          ],
          isCurved: false,
          color: c,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              return FlDotCirclePainter(
                radius: 4.5,
                color: c,
                strokeWidth: 0,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
      ];
    }

    final out = <LineChartBarData>[];
    for (var d = 2; d <= today; d++) {
      final c = colorForDay(d);
      out.add(
        LineChartBarData(
          spots: [
            FlSpot((d - 1).toDouble(), cumCurr[d - 2]),
            FlSpot(d.toDouble(), cumCurr[d - 1]),
          ],
          isCurved: false,
          color: c,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }
    return out;
  }

  double _niceXInterval(int maxDay) {
    if (maxDay <= 7) return 1;
    if (maxDay <= 14) return 2;
    if (maxDay <= 21) return 3;
    return 5;
  }

  String _compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(2)}K';
    return v.toStringAsFixed(0);
  }
}
