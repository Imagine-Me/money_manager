import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';

/// Donut pie: burn vs store totals for the current report selection.
class ReportBurnStorePieCard extends StatefulWidget {
  const ReportBurnStorePieCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.burnTotal,
    required this.storeTotal,
    this.onTap,
    this.largeHero = false,
  });

  final String title;
  final String subtitle;
  final double burnTotal;
  final double storeTotal;
  final VoidCallback? onTap;

  /// Taller chart and pie for detail / hero layouts.
  final bool largeHero;

  @override
  State<ReportBurnStorePieCard> createState() => _ReportBurnStorePieCardState();
}

class _ReportBurnStorePieCardState extends State<ReportBurnStorePieCard> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final burn = widget.burnTotal;
    final store = widget.storeTotal;
    final total = burn + store;
    final pieSide = widget.largeHero ? 158.0 : 136.0;
    final centerR = widget.largeHero ? 40.0 : 34.0;
    final sectionRadius = widget.largeHero ? 46.0 : 42.0;
    final sectionRadiusTouched = widget.largeHero ? 52.0 : 48.0;

    final card = Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (total <= 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'No burn or store in this period',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: pieSide,
                  height: pieSide,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response?.touchedSection == null) {
                              _touchedIndex = null;
                              return;
                            }
                            _touchedIndex = response!
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      centerSpaceRadius: centerR,
                      centerSpaceColor: AppTheme.cardColor,
                      sectionsSpace: 2,
                      sections: _sections(
                        burn,
                        store,
                        total,
                        sectionRadius,
                        sectionRadiusTouched,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LegendRow(
                        label: 'Burn',
                        color: AppTheme.burnColor,
                        amount: burn,
                        total: total,
                      ),
                      const SizedBox(height: 12),
                      _LegendRow(
                        label: 'Store',
                        color: AppTheme.storeColor,
                        amount: store,
                        total: total,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Total ${CurrencyFormatter.format(total)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
    if (widget.onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onTap,
        child: card,
      ),
    );
  }

  List<PieChartSectionData> _sections(
    double burn,
    double store,
    double total,
    double radius,
    double radiusTouched,
  ) {
    final out = <PieChartSectionData>[];
    if (burn > 0) {
      final i = out.length;
      final pct = burn / total * 100;
      final touched = _touchedIndex == i;
      out.add(
        PieChartSectionData(
          value: burn,
          color: AppTheme.burnColor,
          radius: touched ? radiusTouched : radius,
          title: touched ? '${pct.toStringAsFixed(1)}%' : '',
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      );
    }
    if (store > 0) {
      final i = out.length;
      final pct = store / total * 100;
      final touched = _touchedIndex == i;
      out.add(
        PieChartSectionData(
          value: store,
          color: AppTheme.storeColor,
          radius: touched ? radiusTouched : radius,
          title: touched ? '${pct.toStringAsFixed(1)}%' : '',
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      );
    }
    return out;
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.color,
    required this.amount,
    required this.total,
  });

  final String label;
  final Color color;
  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? amount / total * 100 : 0.0;
    const dotSize = 10.0;
    const gap = 10.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      CurrencyFormatter.format(amount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
