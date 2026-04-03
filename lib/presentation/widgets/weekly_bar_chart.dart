import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/theme/app_theme.dart';

class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({super.key, required this.weeklyData});

  /// 7 values: spending per day, starting from 6 days ago → today.
  final List<double> weeklyData;

  @override
  Widget build(BuildContext context) {
    final maxValue = weeklyData.isEmpty
        ? 1.0
        : weeklyData.reduce((a, b) => a > b ? a : b);
    final chartMax = maxValue == 0 ? 100.0 : maxValue * 1.25;

    final now = DateTime.now();
    final days = List.generate(7, (i) {
      return DateTime(now.year, now.month, now.day - (6 - i));
    });

    return BarChart(
      BarChartData(
        maxY: chartMax,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppTheme.cardElevated,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₹${rod.toY.toStringAsFixed(0)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            },
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
                if (value == 0 || value == meta.max) {
                  return Text(
                    '₹${_compact(value)}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 9),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= days.length) {
                  return const SizedBox.shrink();
                }
                final day = days[index];
                final isToday = index == 6;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    isToday ? 'Now' : DateFormat('E').format(day),
                    style: TextStyle(
                      color: isToday ? AppTheme.primaryColor : Colors.white38,
                      fontSize: 11,
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
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
        borderData: FlBorderData(show: false),
        barGroups: List.generate(weeklyData.length, (i) {
          final value = weeklyData[i];
          final isToday = i == 6;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: value,
                width: 18,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                gradient: LinearGradient(
                  colors: isToday
                      ? [AppTheme.primaryColor,
                         AppTheme.primaryColor.withValues(alpha: 0.6)]
                      : [AppTheme.burnColor.withValues(alpha: 0.7),
                         AppTheme.burnColor.withValues(alpha: 0.3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
