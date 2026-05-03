import 'package:flutter/material.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';

/// Single card: account count, balance, net change, chart.
class ReportPortfolioSummaryPanel extends StatelessWidget {
  const ReportPortfolioSummaryPanel({
    super.key,
    required this.accountCount,
    required this.totalBalance,
    required this.netChangeLabel,
    required this.netChangeDelta,
    required this.chartHeight,
    required this.chart,
    this.onTap,
  });

  final int accountCount;
  final double totalBalance;
  final String netChangeLabel;
  final double netChangeDelta;
  final double chartHeight;
  final Widget chart;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final savedColor = netChangeDelta > 0
        ? AppTheme.storeColor
        : netChangeDelta < 0
            ? AppTheme.burnColor
            : Colors.white60;
    final savedText = netChangeDelta > 0
        ? '+${CurrencyFormatter.format(netChangeDelta)}'
        : CurrencyFormatter.format(netChangeDelta);

    final card = Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.45),
                  AppTheme.cardColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$accountCount ${accountCount == 1 ? 'Account' : 'Accounts'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  CurrencyFormatter.format(totalBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        netChangeLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      savedText,
                      style: TextStyle(
                        color: savedColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
            child: SizedBox(
              height: chartHeight,
              child: chart,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
