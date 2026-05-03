import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';
import 'package:money_manager/domain/entities/custom_report_widget_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/presentation/views/report/report_category_spend_helpers.dart';
import 'package:money_manager/presentation/views/report/report_period_data.dart';
import 'package:money_manager/presentation/views/report/report_portfolio_balance.dart';
import 'package:money_manager/presentation/widgets/portfolio_balance_line_chart.dart';

Color _chartColorFor(TransactionType t) => switch (t) {
      TransactionType.store => AppTheme.storeColor,
      TransactionType.income => AppTheme.incomeColor,
      _ => AppTheme.burnColor,
    };

Color _deltaColorFor(TransactionType t, double delta) {
  if (delta == 0) return Colors.white60;
  switch (t) {
    case TransactionType.burn:
      return delta > 0 ? AppTheme.burnColor : AppTheme.storeColor;
    case TransactionType.store:
    case TransactionType.income:
      return delta > 0 ? _chartColorFor(t) : AppTheme.burnColor;
    case TransactionType.transfer:
      return Colors.white54;
  }
}

String _typeChipLabel(TransactionType t) => switch (t) {
      TransactionType.burn => 'Burn',
      TransactionType.store => 'Store',
      TransactionType.income => 'Income',
      TransactionType.transfer => 'Transfer',
    };

String _allTimeLabel(TransactionType t) => switch (t) {
      TransactionType.burn => 'All-time burn (filtered)',
      TransactionType.store => 'All-time stored (filtered)',
      TransactionType.income => 'All-time income (filtered)',
      TransactionType.transfer => 'All-time (filtered)',
    };

/// User-defined tracking for selected categories / subcategories.
class ReportCustomSpendCard extends StatelessWidget {
  const ReportCustomSpendCard({
    super.key,
    required this.entity,
    required this.transactions,
    required this.period,
    required this.selectedDate,
    required this.now,
    required this.onDelete,
    this.onEdit,
    this.showDragHandle = false,
  });

  final CustomReportWidgetEntity entity;
  final List<TransactionEntity> transactions;
  final ReportPeriod period;
  final DateTime selectedDate;
  final DateTime now;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final filter = entity.categoryFilterIds.toSet();
    if (filter.isEmpty) {
      return const SizedBox.shrink();
    }
    final showSubs = entity.showSubcategories;
    final ty = entity.typeFilter;
    final lineColor = _chartColorFor(ty);

    late final String subtitle;
    late final double primarySpend;
    late final double compareSpend;
    late final String compareLabel;
    late final Widget chart;

    switch (period) {
      case ReportPeriod.month:
        final y = selectedDate.year;
        final m = selectedDate.month;
        final thisStart = DateTime(y, m, 1);
        final thisEnd = endOfSelectedMonthCutoff(selectedDate, now);
        final prevStart = DateTime(y, m - 1, 1);
        final prevEnd = endOfMonth(DateTime(y, m - 1, 1));
        primarySpend = sumFilteredBetween(
          transactions,
          thisStart,
          thisEnd,
          ty,
          filter,
          showSubs,
        );
        compareSpend = sumFilteredBetween(
          transactions,
          prevStart,
          prevEnd,
          ty,
          filter,
          showSubs,
        );
        compareLabel = DateFormat('MMM yyyy').format(prevStart);
        final spots = dailyFilteredSpotsInMonth(
          transactions: transactions,
          monthAny: selectedDate,
          now: now,
          type: ty,
          filterIds: filter,
          showSubcategories: showSubs,
        );
        final prevSpots = dailyFilteredSpotsInMonth(
          transactions: transactions,
          monthAny: prevStart,
          now: now,
          type: ty,
          filterIds: filter,
          showSubcategories: showSubs,
        );
        final daysInSel = DateTime(y, m + 1, 0).day;
        var maxX = daysInSel.toDouble();
        if (spots.isNotEmpty) maxX = math.max(maxX, spots.last.x);
        if (prevSpots.isNotEmpty) maxX = math.max(maxX, prevSpots.last.x);
        final interval = niceBottomInterval(maxX.round()).toDouble();
        subtitle =
            '${DateFormat('MMMM yyyy').format(selectedDate)} · vs $compareLabel';
        chart = spots.isEmpty
            ? const Center(
                child: Text(
                  'No amounts this month',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              )
            : PortfolioBalanceLineChart(
                spots: spots,
                minX: 0,
                maxX: maxX,
                bottomTitleInterval: interval,
                formatBottomTitle: (x) {
                  final v = x.round();
                  if (v <= 0) return '';
                  final maxR = maxX.round();
                  if (v == 30 && maxR == 31) return '';
                  return '$v';
                },
                compareSpots: prevSpots.isEmpty ? null : prevSpots,
                lineColor: lineColor,
                yAxisFromZero: true,
              );
        break;

      case ReportPeriod.year:
        final year = selectedDate.year;
        final thisStart = DateTime(year, 1, 1);
        final thisEnd = year < now.year
            ? DateTime(year, 12, 31, 23, 59, 59, 999)
            : DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        final prevStart = DateTime(year - 1, 1, 1);
        final prevEnd = year < now.year
            ? DateTime(year - 1, 12, 31, 23, 59, 59, 999)
            : DateTime(year - 1, now.month, now.day, 23, 59, 59, 999);
        primarySpend = sumFilteredBetween(
          transactions,
          thisStart,
          thisEnd,
          ty,
          filter,
          showSubs,
        );
        compareSpend = sumFilteredBetween(
          transactions,
          prevStart,
          prevEnd,
          ty,
          filter,
          showSubs,
        );
        compareLabel = '${year - 1}';
        final spots = monthlyFilteredSpotsInYear(
          transactions: transactions,
          year: year,
          now: now,
          type: ty,
          filterIds: filter,
          showSubcategories: showSubs,
        );
        final maxX = spots.isEmpty ? 1.0 : spots.last.x;
        final interval = niceBottomInterval(maxX.round()).toDouble();
        subtitle = '$year · vs same period in $compareLabel';
        chart = spots.isEmpty
            ? const Center(
                child: Text(
                  'No data',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              )
            : PortfolioBalanceLineChart(
                spots: spots,
                minX: 0,
                maxX: maxX,
                bottomTitleInterval: interval,
                formatBottomTitle: (x) {
                  final r = x.round();
                  if (r < 1) return '';
                  return DateFormat('MMM').format(DateTime(year, r, 1));
                },
                lineColor: lineColor,
                yAxisFromZero: true,
              );
        break;

      case ReportPeriod.overall:
        primarySpend = sumFilteredBetween(
          transactions,
          DateTime(1970, 1, 1),
          DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
          ty,
          filter,
          showSubs,
        );
        compareSpend = 0;
        compareLabel = '';
        final anchor = DateTime(now.year, now.month, 1);
        final spots = trailingMonthlyFilteredSpots(
          transactions: transactions,
          anchorMonthStart: anchor,
          now: now,
          monthCount: 12,
          type: ty,
          filterIds: filter,
          showSubcategories: showSubs,
        );
        final maxX = spots.isEmpty ? 1.0 : spots.last.x;
        final interval = niceBottomInterval(maxX.round()).toDouble();
        subtitle = 'All-time · last 12 months trend';
        chart = spots.isEmpty
            ? const Center(
                child: Text(
                  'No data',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              )
            : PortfolioBalanceLineChart(
                spots: spots,
                minX: 0,
                maxX: maxX,
                bottomTitleInterval: interval,
                formatBottomTitle: (x) {
                  final xi = x.round();
                  final slots = maxX.round();
                  if (xi <= 0 || xi > slots) return '';
                  final monthsBack = slots - xi;
                  final d =
                      DateTime(anchor.year, anchor.month - monthsBack, 1);
                  return DateFormat('MMM yy').format(d);
                },
                lineColor: lineColor,
                yAxisFromZero: true,
              );
        break;
    }

    final delta = period == ReportPeriod.overall
        ? null
        : primarySpend - compareSpend;
    final deltaColor =
        delta == null ? Colors.white54 : _deltaColorFor(ty, delta);

    final cardBody = Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entity.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: lineColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _typeChipLabel(ty),
                            style: TextStyle(
                              color: lineColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                color: AppTheme.cardElevated,
                onSelected: (v) {
                  if (v == 'delete') onDelete();
                  if (v == 'edit' && onEdit != null) onEdit!();
                },
                itemBuilder: (_) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (period != ReportPeriod.overall) ...[
            Row(
              children: [
                Expanded(
                  child: _SpendBlock(
                    label: period == ReportPeriod.month
                        ? 'This month'
                        : 'This year',
                    value: primarySpend,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: _SpendBlock(
                    label: period == ReportPeriod.month
                        ? 'Last month'
                        : 'Last year',
                    value: compareSpend,
                  ),
                ),
                if (delta != null) ...[
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: _SpendBlock(
                      label: 'Change',
                      value: delta,
                      valueColor: deltaColor,
                      isDelta: true,
                    ),
                  ),
                ],
              ],
            ),
          ] else
            _SpendBlock(
              label: _allTimeLabel(ty),
              value: primarySpend,
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: chart,
          ),
        ],
      ),
    );

    if (!showDragHandle) return cardBody;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 4),
          child: Icon(
            Icons.drag_handle_rounded,
            color: Colors.white.withValues(alpha: 0.28),
            size: 22,
          ),
        ),
        Expanded(child: cardBody),
      ],
    );
  }
}

class _SpendBlock extends StatelessWidget {
  const _SpendBlock({
    required this.label,
    required this.value,
    this.valueColor,
    this.isDelta = false,
  });

  final String label;
  final double value;
  final Color? valueColor;
  final bool isDelta;

  @override
  Widget build(BuildContext context) {
    final text = isDelta
        ? (value > 0
            ? '+${CurrencyFormatter.format(value)}'
            : CurrencyFormatter.format(value))
        : CurrencyFormatter.format(value);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
