import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/domain/entities/category_entity.dart';

class SpendingPieChart extends StatefulWidget {
  const SpendingPieChart({
    super.key,
    required this.data,
    this.centerLabel = 'Spend',
  });

  final Map<CategoryEntity, double> data;
  final String centerLabel;

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(
        child: Text(
          'No data yet',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
      );
    }

    final total = widget.data.values.fold(0.0, (a, b) => a + b);
    final entries = widget.data.entries.toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Pie chart (left) ──────────────────────────────────────────────
        SizedBox(
          width: 150,
          height: 150,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touchedIndex = null;
                      return;
                    }
                    _touchedIndex =
                        response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              centerSpaceRadius: 36,
              centerSpaceColor: AppTheme.cardColor,
              sectionsSpace: 2,
              sections: List.generate(entries.length, (i) {
                final entry = entries[i];
                final isTouched = i == _touchedIndex;
                final pct = entry.value / total * 100;
                return PieChartSectionData(
                  value: entry.value,
                  color: entry.key.color,
                  radius: isTouched ? 52 : 44,
                  title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // ── Legend (right) ────────────────────────────────────────────────
        Expanded(
          child: _Legend(entries: entries, total: total),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.entries, required this.total});

  final List<MapEntry<CategoryEntity, double>> entries;
  final double total;

  @override
  Widget build(BuildContext context) {
    final displayEntries = entries.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: displayEntries
          .map((e) => _LegendItem(
                label: e.key.name,
                color: e.key.color,
                percent: e.value / total * 100,
              ))
          .toList(),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.color,
    required this.percent,
  });

  final String label;
  final Color color;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
