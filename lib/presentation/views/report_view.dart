import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/presentation/providers/providers.dart';
import 'package:money_manager/presentation/widgets/bento_card.dart';
import 'package:money_manager/presentation/widgets/spending_pie_chart.dart';
import 'package:money_manager/presentation/widgets/transaction_list_tile.dart';

// ─── Period enum ──────────────────────────────────────────────────────────────

enum _Period { day, week, month, year }
enum _CompareMode { prevMonth, lastYear }

// ─── View ─────────────────────────────────────────────────────────────────────

class ReportView extends ConsumerStatefulWidget {
  const ReportView({super.key});

  @override
  ConsumerState<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends ConsumerState<ReportView> {
  _Period _period = _Period.month;
  DateTime _selectedDate = DateTime.now();
  _CompareMode _compareMode = _CompareMode.prevMonth;
  bool _showSubcategories = false;

  void _goBack() {
    setState(() {
      switch (_period) {
        case _Period.day:
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
          break;
        case _Period.week:
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
          break;
        case _Period.month:
          _selectedDate =
              DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
          break;
        case _Period.year:
          _selectedDate = DateTime(_selectedDate.year - 1);
          break;
      }
    });
  }

  void _goForward() {
    setState(() {
      switch (_period) {
        case _Period.day:
          _selectedDate = _selectedDate.add(const Duration(days: 1));
          break;
        case _Period.week:
          _selectedDate = _selectedDate.add(const Duration(days: 7));
          break;
        case _Period.month:
          _selectedDate =
              DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          break;
        case _Period.year:
          _selectedDate = DateTime(_selectedDate.year + 1);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionListProvider);
    final catAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Report'),
      ),
      body: txAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: AppTheme.burnColor)),
        ),
        data: (allTx) {
          final allCategories = catAsync.valueOrNull ?? [];
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final selDay = DateTime(
              _selectedDate.year, _selectedDate.month, _selectedDate.day);
          final thisWeekMon =
              today.subtract(Duration(days: today.weekday - 1));
          final selWeekMon =
              selDay.subtract(Duration(days: selDay.weekday - 1));
          final bool canGoNext = switch (_period) {
            _Period.day => selDay.isBefore(today),
            _Period.week => selWeekMon.isBefore(thisWeekMon),
            _Period.month => _selectedDate.year < now.year ||
                (_selectedDate.year == now.year &&
                    _selectedDate.month < now.month),
            _Period.year => _selectedDate.year < now.year,
          };
          final data = _PeriodData.compute(
              allTx, allCategories, _period, _selectedDate);
          final burnBreakdown = _showSubcategories
              ? data.burnBreakdown
              : data.burnParentBreakdown;
          final storeBreakdown = _showSubcategories
              ? data.storeBreakdown
              : data.storeParentBreakdown;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Period selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _PeriodSelector(
                    selected: _period,
                    onChanged: (p) => setState(() {
                      _period = p;
                      _selectedDate = DateTime.now();
                    }),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Period navigator
                    _DateNavigator(
                      label: data.periodLabel,
                      onPrev: _goBack,
                      onNext: canGoNext ? _goForward : null,
                    ),
                    const SizedBox(height: 12),

                    // ─── Hero summary ────────────────────────────────────
                    _SummaryCard(data: data),
                    const SizedBox(height: 12),

                    // ─── Category toggle ─────────────────────────────────
                    _DrillToggle(
                      showSubcategories: _showSubcategories,
                      onChanged: (v) =>
                          setState(() => _showSubcategories = v),
                    ),
                    const SizedBox(height: 12),

                    // ─── Bar chart ───────────────────────────────────────
                    if (data.barValues.any((v) => v > 0)) ...[
                      BentoCard(
                        padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardLabel('SPENDING TREND'),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 170,
                              child: _ReportBarChart(
                                labels: data.barLabels,
                                values: data.barValues,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ─── Where money went ────────────────────────────────
                    if (burnBreakdown.isNotEmpty) ...[
                      BentoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardLabel('WHERE MONEY WENT'),
                            const SizedBox(height: 20),
                            SpendingPieChart(data: burnBreakdown),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category progress bars
                      BentoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardLabel('CATEGORY BREAKDOWN'),
                            const SizedBox(height: 16),
                            ...burnBreakdown.entries.map(
                              (e) => _CategoryBar(
                                category: e.key,
                                amount: e.value,
                                total: data.totalBurn,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ─── Store breakdown ─────────────────────────────────
                    if (storeBreakdown.isNotEmpty) ...[
                      BentoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardLabel('STORE BREAKDOWN'),
                            const SizedBox(height: 16),
                            ...storeBreakdown.entries.map(
                              (e) => _CategoryBar(
                                category: e.key,
                                amount: e.value,
                                total: data.totalStore,
                                color: AppTheme.storeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ─── Spending comparison (month only) ─────────────────
                    if (_period == _Period.month) ...[
                      _SpendingComparisonCard(
                        current: data,
                        compare: _PeriodData.compute(
                          allTx,
                          allCategories,
                          _Period.month,
                          _compareMode == _CompareMode.prevMonth
                              ? DateTime(
                                  _selectedDate.year,
                                  _selectedDate.month - 1,
                                  1)
                              : DateTime(
                                  _selectedDate.year - 1,
                                  _selectedDate.month,
                                  1),
                        ),
                        compareMode: _compareMode,
                        onCompareModeChanged: (m) =>
                            setState(() => _compareMode = m),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ─── Transactions ─────────────────────────────────────
                    BentoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _cardLabel('TRANSACTIONS'),
                              const Spacer(),
                              _CountBadge(count: data.transactions.length),
                            ],
                          ),
                          if (data.transactions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'No transactions for this period',
                                  style: TextStyle(color: Colors.white38),
                                ),
                              ),
                            )
                          else ...[
                            const SizedBox(height: 8),
                            ...data.transactions.map(
                              (tx) => TransactionListTile(
                                transaction: tx,
                                onDelete: () => ref
                                    .read(transactionRepositoryProvider)
                                    .delete(tx.id),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Period selector ──────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final _Period selected;
  final ValueChanged<_Period> onChanged;

  static const _labels = {
    _Period.day: 'Day',
    _Period.week: 'Week',
    _Period.month: 'Month',
    _Period.year: 'Year',
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
        children: _Period.values.map((p) {
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

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _PeriodData data;

  @override
  Widget build(BuildContext context) {
    final net = data.totalStore - data.totalBurn;
    final netPositive = net >= 0;

    return BentoCard(
      gradient: LinearGradient(
        colors: [
          AppTheme.primaryColor.withValues(alpha: 0.18),
          AppTheme.cardColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Burn
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppTheme.burnColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: AppTheme.burnColor,
                            size: 13),
                      ),
                      const SizedBox(width: 6),
                      const Text('BURN',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatCompact(data.totalBurn),
                    style: const TextStyle(
                      color: AppTheme.burnColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${data.burnCount} txn',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.white.withValues(alpha: 0.08),
            ),

            // Net
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('NET',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatCompact(net.abs()),
                    style: TextStyle(
                      color: netPositive
                          ? AppTheme.storeColor
                          : AppTheme.burnColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    netPositive ? 'surplus' : 'deficit',
                    style: TextStyle(
                      color: netPositive
                          ? AppTheme.storeColor.withValues(alpha: 0.6)
                          : AppTheme.burnColor.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.white.withValues(alpha: 0.08),
            ),

            // Store
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('STORE',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.storeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.savings_rounded,
                            color: AppTheme.storeColor, size: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatCompact(data.totalStore),
                    style: const TextStyle(
                      color: AppTheme.storeColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${data.storeCount} txn',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bar chart ────────────────────────────────────────────────────────────────

class _ReportBarChart extends StatelessWidget {
  const _ReportBarChart({required this.labels, required this.values});

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
            getTooltipItem: (group, _, rod, __) {
              final idx = group.x;
              final label = idx >= 0 && idx < labels.length ? labels[idx] : '';
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
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 9),
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

// ─── Category progress bar row ────────────────────────────────────────────────

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
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
              valueColor: AlwaysStoppedAnimation<Color>(
                  barColor.withValues(alpha: 0.8)),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Count badge ──────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
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

// ─── Shared label style ───────────────────────────────────────────────────────

Widget _cardLabel(String text) => Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );

// ─── Drill Toggle ─────────────────────────────────────────────────────────────

class _DrillToggle extends StatelessWidget {
  const _DrillToggle(
      {required this.showSubcategories, required this.onChanged});

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
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _chip('Category', !showSubcategories, () => onChanged(false)),
              const SizedBox(width: 4),
              _chip(
                  'Subcategory', showSubcategories, () => onChanged(true)),
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

// ─── Date navigator ─────────────────────────────────────────────────────────

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.label,
    required this.onPrev,
    this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _navButton(Icons.chevron_left, onPrev),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        _navButton(Icons.chevron_right, onNext),
      ],
    );
  }

  Widget _navButton(IconData icon, VoidCallback? onTap) {
    return Opacity(
      opacity: onTap != null ? 1.0 : 0.25,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: Colors.white70, size: 16),
        ),
      ),
    );
  }
}

// ─── Spending comparison card ─────────────────────────────────────────────────

class _SpendingComparisonCard extends StatelessWidget {
  const _SpendingComparisonCard({
    required this.current,
    required this.compare,
    required this.compareMode,
    required this.onCompareModeChanged,
  });

  final _PeriodData current;
  final _PeriodData compare;
  final _CompareMode compareMode;
  final ValueChanged<_CompareMode> onCompareModeChanged;

  @override
  Widget build(BuildContext context) {
    final burnDelta = compare.totalBurn > 0
        ? (current.totalBurn - compare.totalBurn) / compare.totalBurn * 100
        : null;
    final storeDelta = compare.totalStore > 0
        ? (current.totalStore - compare.totalStore) /
            compare.totalStore *
            100
        : null;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _cardLabel('SPENDING COMPARISON'),
              const Spacer(),
              _CompareModeToggle(
                mode: compareMode,
                onChanged: onCompareModeChanged,
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
                    burn: current.totalBurn,
                    store: current.totalStore,
                    isCurrent: true,
                  ),
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
                    burn: compare.totalBurn,
                    store: compare.totalStore,
                    isCurrent: false,
                  ),
                ),
              ],
            ),
          ),
          if (burnDelta != null || storeDelta != null) ...[
            const SizedBox(height: 10),
            Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 10),
            Row(
              children: [
                if (burnDelta != null)
                  Expanded(
                      child: _DeltaChip(
                          label: 'Burn',
                          pct: burnDelta,
                          invertColor: true)),
                if (storeDelta != null)
                  Expanded(
                      child:
                          _DeltaChip(label: 'Store', pct: storeDelta)),
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
    required this.burn,
    required this.store,
    required this.isCurrent,
  });

  final String label;
  final double burn;
  final double store;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isCurrent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isCurrent ? Colors.white60 : Colors.white38,
            fontSize: 11,
            fontWeight:
                isCurrent ? FontWeight.w600 : FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          CurrencyFormatter.formatCompact(burn),
          style: TextStyle(
            color: isCurrent
                ? AppTheme.burnColor
                : AppTheme.burnColor.withValues(alpha: 0.45),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'burn',
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 6),
        Text(
          CurrencyFormatter.formatCompact(store),
          style: TextStyle(
            color: isCurrent
                ? AppTheme.storeColor
                : AppTheme.storeColor.withValues(alpha: 0.45),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'store',
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
  // invertColor=true for burn: spending more is bad (red)
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

class _CompareModeToggle extends StatelessWidget {
  const _CompareModeToggle({required this.mode, required this.onChanged});

  final _CompareMode mode;
  final ValueChanged<_CompareMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppTheme.bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip('Prev Month', _CompareMode.prevMonth),
          _chip('Last Year', _CompareMode.lastYear),
        ],
      ),
    );
  }

  Widget _chip(String label, _CompareMode m) {
    final sel = mode == m;
    return GestureDetector(
      onTap: () => onChanged(m),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: sel
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? AppTheme.primaryColor : Colors.white38,
            fontSize: 10,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Period data computation ──────────────────────────────────────────────────

class _PeriodData {
  final double totalBurn;
  final double totalStore;
  final int burnCount;
  final int storeCount;
  final Map<CategoryEntity, double> burnBreakdown;
  final Map<CategoryEntity, double> storeBreakdown;
  final Map<CategoryEntity, double> burnParentBreakdown;
  final Map<CategoryEntity, double> storeParentBreakdown;
  final List<TransactionEntity> transactions;
  final List<String> barLabels;
  final List<double> barValues;
  final String periodLabel;

  const _PeriodData({
    required this.totalBurn,
    required this.totalStore,
    required this.burnCount,
    required this.storeCount,
    required this.burnBreakdown,
    required this.storeBreakdown,
    required this.burnParentBreakdown,
    required this.storeParentBreakdown,
    required this.transactions,
    required this.barLabels,
    required this.barValues,
    required this.periodLabel,
  });

  factory _PeriodData.compute(
      List<TransactionEntity> all,
      List<CategoryEntity> allCategories,
      _Period period,
      DateTime selectedDate) {
    final now = selectedDate;
    List<TransactionEntity> filtered;
    List<String> labels;
    List<double> values;
    String periodLabel;

    switch (period) {
      case _Period.day:
        filtered = all
            .where((t) =>
                t.date.year == now.year &&
                t.date.month == now.month &&
                t.date.day == now.day)
            .toList();
        // Hourly bars
        labels = List.generate(24, (h) {
          if (h == 0) return '12AM';
          if (h < 12) return '${h}AM';
          if (h == 12) return '12PM';
          return '${h - 12}PM';
        });
        values = List.generate(24, (h) => filtered
            .where((t) =>
                t.type == TransactionType.burn && t.date.hour == h)
            .fold(0.0, (s, t) => s + t.amount));
        periodLabel = DateFormat('EEEE, d MMMM yyyy').format(now);
        break;

      case _Period.week:
        // Mon → Sun of current week
        final weekStart = DateTime(
            now.year, now.month, now.day - (now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        filtered = all.where((t) {
          final d = DateTime(t.date.year, t.date.month, t.date.day);
          return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
        }).toList();
        labels = List.generate(7,
            (i) => DateFormat('EEE').format(weekStart.add(Duration(days: i))));
        values = List.generate(7, (i) {
          final d = weekStart.add(Duration(days: i));
          return filtered
              .where((t) =>
                  t.type == TransactionType.burn &&
                  t.date.year == d.year &&
                  t.date.month == d.month &&
                  t.date.day == d.day)
              .fold(0.0, (s, t) => s + t.amount);
        });
        periodLabel =
            '${DateFormat('d MMM').format(weekStart)} – ${DateFormat('d MMM yyyy').format(weekEnd)}';
        break;

      case _Period.month:
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        filtered = all
            .where((t) =>
                t.date.year == now.year && t.date.month == now.month)
            .toList();
        labels = List.generate(daysInMonth, (i) => '${i + 1}');
        values = List.generate(daysInMonth, (i) => filtered
            .where((t) =>
                t.type == TransactionType.burn && t.date.day == i + 1)
            .fold(0.0, (s, t) => s + t.amount));
        periodLabel = DateFormat('MMMM yyyy').format(now);
        break;

      case _Period.year:
        filtered = all.where((t) => t.date.year == now.year).toList();
        labels = List.generate(
            12,
            (i) =>
                DateFormat('MMM').format(DateTime(now.year, i + 1)));
        values = List.generate(
            12,
            (m) => filtered
                .where((t) =>
                    t.type == TransactionType.burn &&
                    t.date.month == m + 1)
                .fold(0.0, (s, t) => s + t.amount));
        periodLabel = now.year.toString();
        break;
    }

    // Sort newest first
    filtered.sort((a, b) => b.date.compareTo(a.date));

    final totalBurn = filtered
        .where((t) => t.type == TransactionType.burn)
        .fold(0.0, (s, t) => s + t.amount);
    final totalStore = filtered
        .where((t) => t.type == TransactionType.store)
        .fold(0.0, (s, t) => s + t.amount);

    final burnBreakdown = _breakdown(filtered, TransactionType.burn);
    final storeBreakdown = _breakdown(filtered, TransactionType.store);

    return _PeriodData(
      totalBurn: totalBurn,
      totalStore: totalStore,
      burnCount:
          filtered.where((t) => t.type == TransactionType.burn).length,
      storeCount:
          filtered.where((t) => t.type == TransactionType.store).length,
      burnBreakdown: burnBreakdown,
      storeBreakdown: storeBreakdown,
      burnParentBreakdown: _parentBreakdown(burnBreakdown, allCategories),
      storeParentBreakdown: _parentBreakdown(storeBreakdown, allCategories),
      transactions: filtered,
      barLabels: labels,
      barValues: values,
      periodLabel: periodLabel,
    );
  }

  static Map<CategoryEntity, double> _breakdown(
      List<TransactionEntity> txns, TransactionType type) {
    final map = <CategoryEntity, double>{};
    for (final t in txns) {
      if (t.type != type || t.category == null) continue;
      map[t.category!] = (map[t.category!] ?? 0) + t.amount;
    }
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  static Map<CategoryEntity, double> _parentBreakdown(
      Map<CategoryEntity, double> breakdown,
      List<CategoryEntity> allCategories) {
    final map = <CategoryEntity, double>{};
    for (final entry in breakdown.entries) {
      final cat = entry.key;
      if (cat.parentId == null) {
        map[cat] = (map[cat] ?? 0) + entry.value;
      } else {
        final idx = allCategories.indexWhere((c) => c.id == cat.parentId);
        final parent = idx >= 0 ? allCategories[idx] : cat;
        map[parent] = (map[parent] ?? 0) + entry.value;
      }
    }
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }
}
