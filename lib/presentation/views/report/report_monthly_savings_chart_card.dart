import 'package:flutter/material.dart';
import 'package:money_manager/core/theme/app_theme.dart';

/// Second chart card: combined balance at each month-end (title + chart).
class ReportMonthlySavingsChartCard extends StatelessWidget {
  const ReportMonthlySavingsChartCard({
    super.key,
    required this.title,
    required this.chartHeight,
    required this.chart,
  });

  final String title;
  final double chartHeight;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: chartHeight,
            child: chart,
          ),
        ],
      ),
    );
  }
}
