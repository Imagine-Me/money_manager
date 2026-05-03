import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/presentation/views/report/report_period_data.dart';
import 'package:money_manager/presentation/views/report/report_dialogs.dart';
import 'package:money_manager/presentation/widgets/bento_card.dart';
import 'package:money_manager/presentation/widgets/spending_pie_chart.dart';

// ─── Card section label ───────────────────────────────────────────────────────

Widget cardLabel(String text) => Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );

// ─── Type badge ───────────────────────────────────────────────────────────────

class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.type});

  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final accent = type == TransactionType.burn
        ? AppTheme.burnColor
        : type == TransactionType.income
            ? AppTheme.incomeColor
            : AppTheme.storeColor;
    final icon = type == TransactionType.burn
        ? Icons.local_fire_department_rounded
        : type == TransactionType.income
            ? Icons.account_balance_wallet_rounded
            : Icons.savings_rounded;
    final label = type == TransactionType.burn
        ? 'BURN'
        : type == TransactionType.income
            ? 'INCOME'
            : 'STORE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Period selector ──────────────────────────────────────────────────────────

class PeriodSelector extends StatelessWidget {
  const PeriodSelector(
      {super.key, required this.selected, required this.onChanged});

  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  static const _labels = {
    ReportPeriod.month: 'Month',
    ReportPeriod.year: 'Year',
    ReportPeriod.overall: 'Overall',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: ReportPeriod.values.map((p) {
          final isSelected = p == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[p]!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white38,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Date navigator ───────────────────────────────────────────────────────────

class DateNavigator extends StatelessWidget {
  const DateNavigator({
    super.key,
    required this.label,
    required this.onPrev,
    this.onNext,
    this.compact = false,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: Colors.white70,
      fontSize: compact ? 12 : 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    return Row(
      children: [
        _navBtn(Icons.chevron_left, onPrev),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
        _navBtn(Icons.chevron_right, onNext),
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) => Opacity(
        opacity: onTap != null ? 1.0 : 0.25,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(compact ? 4 : 6),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(compact ? 7 : 8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, color: Colors.white70, size: compact ? 15 : 16),
          ),
        ),
      );
}

// ─── Compact period + date row (reports) ─────────────────────────────────────

/// Single row: short period control + date navigation (or subtitle for overall).
class CompactReportPeriodHeader extends StatelessWidget {
  const CompactReportPeriodHeader({
    super.key,
    required this.period,
    required this.onPeriodChanged,
    required this.dateLabel,
    required this.onPrev,
    required this.onNext,
    required this.showNavigator,
  });

  final ReportPeriod period;
  final ValueChanged<ReportPeriod> onPeriodChanged;
  final String dateLabel;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final bool showNavigator;

  static ButtonStyle _segmentStyle() {
    return SegmentedButton.styleFrom(
      backgroundColor: AppTheme.cardColor,
      selectedBackgroundColor: AppTheme.primaryColor,
      selectedForegroundColor: Colors.white,
      foregroundColor: Colors.white54,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      textStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SegmentedButton<ReportPeriod>(
          showSelectedIcon: false,
          style: _segmentStyle(),
          segments: const [
            ButtonSegment<ReportPeriod>(
              value: ReportPeriod.month,
              label: Text('Mo'),
              tooltip: 'Month',
            ),
            ButtonSegment<ReportPeriod>(
              value: ReportPeriod.year,
              label: Text('Yr'),
              tooltip: 'Year',
            ),
            ButtonSegment<ReportPeriod>(
              value: ReportPeriod.overall,
              label: Text('All'),
              tooltip: 'Overall',
            ),
          ],
          selected: {period},
          onSelectionChanged: (next) {
            if (next.isEmpty) return;
            onPeriodChanged(next.first);
          },
        ),
        const SizedBox(width: 10),
        if (showNavigator)
          Expanded(
            child: DateNavigator(
              label: dateLabel,
              onPrev: onPrev,
              onNext: onNext,
              compact: true,
            ),
          )
        else
          Expanded(
            child: Text(
              'Last 24 months',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.38),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Drill toggle ─────────────────────────────────────────────────────────────

class DrillToggle extends StatelessWidget {
  const DrillToggle(
      {super.key, required this.showSubcategories, required this.onChanged});

  final bool showSubcategories;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'VIEW BY',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _chip('Category', !showSubcategories, () => onChanged(false)),
              const SizedBox(width: 4),
              _chip('Subcategory', showSubcategories, () => onChanged(true)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white38,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      );
}

// ─── Filter icon button ───────────────────────────────────────────────────────

class FilterIconButton extends StatelessWidget {
  const FilterIconButton(
      {super.key, required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.filter_list_rounded,
              color: isActive ? AppTheme.primaryColor : Colors.white54,
              size: 16,
            ),
            if (isActive)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.cardColor, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Save preset button ───────────────────────────────────────────────────────

class SavePresetButton extends StatelessWidget {
  const SavePresetButton({super.key, required this.onTap, this.isActive = false});

  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Icon(
          isActive ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
          color: isActive ? AppTheme.primaryColor : Colors.white54,
          size: 16,
        ),
      ),
    );
  }
}

// ─── Count badge ──────────────────────────────────────────────────────────────

class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.data,
    required this.type,
    this.deltaAmount,
  });

  final PeriodData data;
  final TransactionType type;
  final double? deltaAmount;

  @override
  Widget build(BuildContext context) {
    final accent = type == TransactionType.burn
        ? AppTheme.burnColor
        : type == TransactionType.income
            ? AppTheme.incomeColor
            : AppTheme.storeColor;
    final icon = type == TransactionType.burn
        ? Icons.local_fire_department_rounded
        : type == TransactionType.income
            ? Icons.account_balance_wallet_rounded
            : Icons.savings_rounded;
    final amount = data.totalFor(type);
    final count = data.countFor(type);
    final typeLabel = type == TransactionType.burn
        ? 'BURN'
        : type == TransactionType.income
            ? 'INCOME'
            : 'STORE';
    final delta = deltaAmount;
    final isDeltaUp = (delta ?? 0) > 0;
    // For burn: going up is bad (red). For store/income: going up is good (teal).
    final deltaIsGood = type == TransactionType.burn ? !isDeltaUp : isDeltaUp;
    final deltaColor = delta == null || delta.abs() < 0.01
        ? Colors.white38
        : deltaIsGood
            ? AppTheme.storeColor
            : AppTheme.burnColor;
    final deltaIcon = delta == null
        ? null
        : isDeltaUp
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;

    return BentoCard(
      gradient: LinearGradient(
        colors: [
          AppTheme.primaryColor.withValues(alpha: 0.18),
          AppTheme.cardColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: accent, size: 13),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      typeLabel,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(amount),
                  style: TextStyle(
                    color: accent,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$count txn',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          if (delta != null && deltaIcon != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: deltaColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: deltaColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(deltaIcon, color: deltaColor, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    CurrencyFormatter.formatCompact(delta.abs()),
                    style: TextStyle(
                      color: deltaColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Report bar chart ─────────────────────────────────────────────────────────

class ReportBarChart extends StatelessWidget {
  const ReportBarChart({super.key, required this.labels, required this.values});

  final List<String> labels;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final maxVal =
        values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final chartMax = maxVal == 0 ? 100.0 : maxVal * 1.25;

    return BarChart(
      BarChartData(
        maxY: chartMax,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppTheme.cardElevated,
            getTooltipItem: (group, ignored1, rod, ignored2) {
              final idx = group.x;
              final label =
                  idx >= 0 && idx < labels.length ? labels[idx] : '';
              return BarTooltipItem(
                '$label\n₹${rod.toY.toStringAsFixed(0)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
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
                    _compact(value),
                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                final step = (labels.length / 6).ceil().clamp(1, 999);
                if (idx % step != 0) return const SizedBox.shrink();
                return Transform.translate(
                  offset: const Offset(0, 4),
                  child: Text(
                    labels[idx],
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: chartMax / 4,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(values.length, (i) {
          final isMax = maxVal > 0 && values[i] == maxVal;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                color: isMax
                    ? AppTheme.burnColor
                    : AppTheme.primaryColor.withValues(alpha: 0.7),
                width: _barWidth(values.length),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }

  double _barWidth(int count) {
    if (count <= 7) return 18;
    if (count <= 14) return 12;
    if (count <= 24) return 8;
    if (count <= 31) return 7;
    return 14;
  }

  String _compact(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(0)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}k';
    return '₹${v.toStringAsFixed(0)}';
  }
}

// ─── Category bar ─────────────────────────────────────────────────────────────

class CategoryBar extends StatelessWidget {
  const CategoryBar({
    super.key,
    required this.category,
    required this.amount,
    required this.total,
    this.color,
  });

  final CategoryEntity category;
  final double amount;
  final double total;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total) : 0.0;
    final barColor = color ?? category.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CurrencyFormatter.formatCompact(amount),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: barColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor:
                  AlwaysStoppedAnimation<Color>(barColor.withValues(alpha: 0.8)),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Spending comparison card ─────────────────────────────────────────────────

class SpendingComparisonCard extends StatelessWidget {
  const SpendingComparisonCard({
    super.key,
    required this.current,
    required this.currentDate,
    required this.period,
    required this.selectedType,
    required this.compare,
    required this.compareDate,
    required this.onCompareDateChanged,
  });

  final PeriodData current;
  final DateTime currentDate;
  final ReportPeriod period;
  final TransactionType selectedType;
  final PeriodData compare;
  final DateTime compareDate;
  final ValueChanged<DateTime> onCompareDateChanged;

  String _chipLabel() {
    switch (period) {
      case ReportPeriod.month:
        return DateFormat('MMM yyyy').format(compareDate);
      case ReportPeriod.year:
        return compareDate.year.toString();
      case ReportPeriod.overall:
        return 'N/A';
    }
  }

  Future<void> _openPicker(BuildContext context) async {
    switch (period) {
      case ReportPeriod.month:
        if (!context.mounted) break;
        final picked = await showDialog<DateTime>(
          context: context,
          builder: (_) => ReportMonthPickerDialog(
            initial: compareDate,
            currentDate: currentDate,
          ),
        );
        if (picked != null) onCompareDateChanged(picked);
        break;
      case ReportPeriod.year:
        if (!context.mounted) break;
        final picked = await showDialog<int>(
          context: context,
          builder: (_) => ReportYearPickerDialog(
            initial: compareDate.year,
            currentYear: currentDate.year,
          ),
        );
        if (picked != null) onCompareDateChanged(DateTime(picked));
        break;
      case ReportPeriod.overall:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = current.totalFor(selectedType);
    final compareValue = compare.totalFor(selectedType);
    final pctDelta = compareValue > 0
        ? (currentValue - compareValue) / compareValue * 100
        : null;
    final typeLabel = selectedType == TransactionType.burn
        ? 'Burn'
        : selectedType == TransactionType.income
            ? 'Income'
            : 'Store';

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              cardLabel('SPENDING COMPARISON'),
              const Spacer(),
              GestureDetector(
                onTap: () => _openPicker(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _chipLabel(),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.expand_more_rounded,
                          color: AppTheme.primaryColor, size: 13),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _CompCol(
                      label: current.periodLabel,
                      value: currentValue,
                      type: selectedType,
                      isCurrent: true),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: 1,
                          height: 28,
                          color: Colors.white.withValues(alpha: 0.08)),
                      const SizedBox(height: 4),
                      Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                          width: 1,
                          height: 28,
                          color: Colors.white.withValues(alpha: 0.08)),
                    ],
                  ),
                ),
                Expanded(
                  child: _CompCol(
                      label: compare.periodLabel,
                      value: compareValue,
                      type: selectedType,
                      isCurrent: false),
                ),
              ],
            ),
          ),
          if (pctDelta != null) ...[
            const SizedBox(height: 10),
            Container(
                height: 1, color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DeltaChip(
                    label: typeLabel,
                    pct: pctDelta,
                    invertColor: selectedType == TransactionType.burn,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CompCol extends StatelessWidget {
  const _CompCol({
    required this.label,
    required this.value,
    required this.type,
    required this.isCurrent,
  });

  final String label;
  final double value;
  final TransactionType type;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final accent = type == TransactionType.burn
        ? AppTheme.burnColor
        : type == TransactionType.income
            ? AppTheme.incomeColor
            : AppTheme.storeColor;
    return Column(
      crossAxisAlignment:
          isCurrent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isCurrent ? Colors.white60 : Colors.white38,
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          CurrencyFormatter.formatCompact(value),
          style: TextStyle(
            color: isCurrent
                ? accent
                : accent.withValues(alpha: 0.45),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          type.label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({
    required this.label,
    required this.pct,
    this.invertColor = false,
  });

  final String label;
  final double pct;
  final bool invertColor;

  @override
  Widget build(BuildContext context) {
    final isUp = pct > 0;
    final isGood = invertColor ? !isUp : isUp;
    final color = pct.abs() < 0.1
        ? Colors.white38
        : isGood
            ? AppTheme.storeColor
            : AppTheme.burnColor;
    final icon = pct.abs() < 0.1
        ? Icons.remove_rounded
        : isUp
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 3),
        Text(
          '$label ${pct.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Spending breakdown section ───────────────────────────────────────────────

class SpendingBreakdownSection extends StatelessWidget {
  const SpendingBreakdownSection({
    super.key,
    required this.breakdown,
    required this.total,
    required this.type,
  });

  final Map<CategoryEntity, double> breakdown;
  final double total;
  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final isBurn = type == TransactionType.burn;
    final accent = isBurn ? AppTheme.burnColor : AppTheme.storeColor;

    return Column(
      children: [
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cardLabel(
                  isBurn ? 'WHERE MONEY WENT' : 'WHERE MONEY STORED'),
              const SizedBox(height: 20),
              SpendingPieChart(data: breakdown),
            ],
          ),
        ),
        const SizedBox(height: 12),
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cardLabel('CATEGORY BREAKDOWN'),
              const SizedBox(height: 16),
              ...breakdown.entries.map(
                (e) => CategoryBar(
                  category: e.key,
                  amount: e.value,
                  total: total,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
