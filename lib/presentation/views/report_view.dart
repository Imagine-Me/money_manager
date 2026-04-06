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

enum _Period { month, year, overall }

enum _TypeTab { burn, store }

// ─── View ─────────────────────────────────────────────────────────────────────

class ReportView extends ConsumerStatefulWidget {
  const ReportView({super.key});

  @override
  ConsumerState<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends ConsumerState<ReportView> {
  _Period _period = _Period.month;
  _TypeTab _selectedTab = _TypeTab.burn;
  DateTime _selectedDate = DateTime.now();
  // default compare target = one month before _selectedDate
  DateTime _compareDate = DateTime(
      DateTime.now().year, DateTime.now().month - 1, 1);
  bool _showSubcategories = false;
  CategoryEntity? _selectedCategoryFilter;

  TransactionType get _selectedType =>
      _selectedTab == _TypeTab.burn
          ? TransactionType.burn
          : TransactionType.store;

  void _goBack() {
    setState(() {
      switch (_period) {
        case _Period.month:
          final prevSel =
              DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
          _selectedDate = prevSel;
          _compareDate =
              DateTime(prevSel.year, prevSel.month - 1, 1);
          break;
        case _Period.year:
          _selectedDate = DateTime(_selectedDate.year - 1);
          _compareDate = DateTime(_selectedDate.year - 1);
          break;
        case _Period.overall:
          break;
      }
      _selectedCategoryFilter = null;
    });
  }

  void _goForward() {
    setState(() {
      switch (_period) {
        case _Period.month:
          final nextSel =
              DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          _selectedDate = nextSel;
          _compareDate =
              DateTime(nextSel.year, nextSel.month - 1, 1);
          break;
        case _Period.year:
          _selectedDate = DateTime(_selectedDate.year + 1);
          _compareDate = DateTime(_selectedDate.year - 1);
          break;
        case _Period.overall:
          break;
      }
      _selectedCategoryFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionListProvider);
    final catAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: txAsync.when(
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
          final bool canGoNext = switch (_period) {
            _Period.month => _selectedDate.year < now.year ||
                (_selectedDate.year == now.year &&
                    _selectedDate.month < now.month),
            _Period.year => _selectedDate.year < now.year,
            _Period.overall => false,
          };
          final data = _PeriodData.compute(
            allTx,
            allCategories,
            _period,
            _selectedDate,
            typeFilter: _selectedType,
          );
          final selectedBreakdown = _showSubcategories
              ? data.breakdownFor(_selectedType)
              : data.parentBreakdownFor(_selectedType);
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _TypeSelector(
                      selected: _selectedTab,
                      onChanged: (tab) => setState(() {
                        _selectedTab = tab;
                        _selectedCategoryFilter = null;
                      }),
                    ),
                  ),
                ),

                // Period selector
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _PeriodSelector(
                      selected: _period,
                      onChanged: (p) => setState(() {
                        final now = DateTime.now();
                        _period = p;
                        _selectedDate = now;
                        _selectedCategoryFilter = null;
                        switch (p) {
                          case _Period.month:
                            _compareDate =
                                DateTime(now.year, now.month - 1, 1);
                            break;
                          case _Period.year:
                            _compareDate = DateTime(now.year - 1);
                            break;
                          case _Period.overall:
                            _compareDate = DateTime(2000);
                            break;
                        }
                      }),
                    ),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Period navigator
                    if (_period != _Period.overall) ...[
                      _DateNavigator(
                        label: data.periodLabel,
                        onPrev: _goBack,
                        onNext: canGoNext ? _goForward : null,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ─── Hero summary ────────────────────────────────────
                    _SummaryCard(
                      data: data,
                      type: _selectedType,
                      deltaAmount: () {
                        if (_period == _Period.month) {
                          final sel = _selectedDate;
                          final day = sel.day;
                          final curStart = DateTime(sel.year, sel.month, 1);
                          final curEnd = DateTime(sel.year, sel.month, day, 23, 59, 59, 999);
                          final prevStart = DateTime(sel.year, sel.month - 1, 1);
                          final prevDays = DateTime(prevStart.year, prevStart.month + 1, 0).day;
                          final prevDay = day <= prevDays ? day : prevDays;
                          final prevEnd = DateTime(prevStart.year, prevStart.month, prevDay, 23, 59, 59, 999);
                          double sum(DateTime s, DateTime e) => allTx
                              .where((t) => t.type == _selectedType && !t.date.isBefore(s) && !t.date.isAfter(e))
                              .fold(0.0, (a, t) => a + t.amount);
                          return sum(curStart, curEnd) - sum(prevStart, prevEnd);
                        } else if (_period == _Period.year) {
                          final sel = _selectedDate;
                          final curStart = DateTime(sel.year, 1, 1);
                          final curEnd = DateTime(sel.year, sel.month + 1, 0, 23, 59, 59, 999);
                          final prevStart = DateTime(sel.year - 1, 1, 1);
                          final prevEnd = DateTime(sel.year - 1, sel.month + 1, 0, 23, 59, 59, 999);
                          double sum(DateTime s, DateTime e) => allTx
                              .where((t) => t.type == _selectedType && !t.date.isBefore(s) && !t.date.isAfter(e))
                              .fold(0.0, (a, t) => a + t.amount);
                          return sum(curStart, curEnd) - sum(prevStart, prevEnd);
                        }
                        return null;
                      }(),
                    ),
                    const SizedBox(height: 12),

                    // ─── Category toggle ─────────────────────────────────
                    _DrillToggle(
                      showSubcategories: _showSubcategories,
                      onChanged: (v) => setState(() {
                        _showSubcategories = v;
                        _selectedCategoryFilter = null;
                      }),
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
                    if (selectedBreakdown.isNotEmpty) ...[
                      BentoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardLabel(_selectedType == TransactionType.burn
                                ? 'WHERE MONEY WENT'
                                : 'WHERE MONEY STORED'),
                            const SizedBox(height: 20),
                            SpendingPieChart(data: selectedBreakdown),
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
                            ...selectedBreakdown.entries.map(
                              (e) => _CategoryBar(
                                category: e.key,
                                amount: e.value,
                                total: data.totalFor(_selectedType),
                                color: _selectedType == TransactionType.burn
                                    ? AppTheme.burnColor
                                    : AppTheme.storeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ─── Spending comparison ──────────────────────────────
                    if (_period != _Period.overall) ...[  
                      _SpendingComparisonCard(
                        current: data,
                        currentDate: _selectedDate,
                        period: _period,
                        selectedType: _selectedType,
                        compare: _PeriodData.compute(
                          allTx,
                          allCategories,
                          _period,
                          _compareDate,
                          typeFilter: _selectedType,
                        ),
                        compareDate: _compareDate,
                        onCompareDateChanged: (d) =>
                            setState(() => _compareDate = d),
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
                          // ── Category filter chips ──
                          if (selectedBreakdown.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ...selectedBreakdown.keys.map((cat) {
                                    final isSelected = _selectedCategoryFilter?.id == cat.id;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _selectedCategoryFilter =
                                              isSelected ? null : cat;
                                        }),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 160),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? cat.color.withValues(alpha: 0.2)
                                                : AppTheme.bgColor,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isSelected
                                                  ? cat.color
                                                  : Colors.white.withValues(alpha: 0.1),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: BoxDecoration(
                                                  color: cat.color,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                cat.name,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.white54,
                                                  fontSize: 11,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                          Builder(builder: (_) {
                            final filtered = _selectedCategoryFilter == null
                                ? data.transactions
                                : data.transactions.where((tx) {
                                    if (tx.category == null) return false;
                                    if (_showSubcategories) {
                                      return tx.category!.id ==
                                          _selectedCategoryFilter!.id;
                                    } else {
                                      // category mode: match parent or the cat itself
                                      final cat = tx.category!;
                                      final matchId = cat.parentId ?? cat.id;
                                      return matchId ==
                                          _selectedCategoryFilter!.id;
                                    }
                                  }).toList();
                            if (filtered.isEmpty)
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: Text(
                                    'No transactions for this period',
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                ),
                              );
                            return Column(
                              children: [
                                const SizedBox(height: 8),
                                ...filtered.map(
                                  (tx) => TransactionListTile(
                                    transaction: tx,
                                    onDelete: () => ref
                                        .read(transactionRepositoryProvider)
                                        .delete(tx.id),
                                  ),
                                ),
                              ],
                            );
                          }),
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
    _Period.month: 'Month',
    _Period.year: 'Year',
    _Period.overall: 'Overall',
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

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});

  final _TypeTab selected;
  final ValueChanged<_TypeTab> onChanged;

  static const _labels = {
    _TypeTab.burn: 'Burn',
    _TypeTab.store: 'Store',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _TypeTab.values.map((tab) {
        final isSelected = tab == selected;
        final accent = tab == _TypeTab.burn
            ? AppTheme.burnColor
            : AppTheme.storeColor;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _labels[tab]!,
                style: TextStyle(
                  color: isSelected ? accent : Colors.white38,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.data,
    required this.type,
    this.deltaAmount,
  });

  final _PeriodData data;
  final TransactionType type;
  final double? deltaAmount;

  @override
  Widget build(BuildContext context) {
    final isBurn = type == TransactionType.burn;
    final accent = isBurn ? AppTheme.burnColor : AppTheme.storeColor;
    final icon =
        isBurn ? Icons.local_fire_department_rounded : Icons.savings_rounded;
    final label = isBurn ? 'BURN' : 'STORE';
    final amount = data.totalFor(type);
    final count = data.countFor(type);

    // Delta display
    final delta = deltaAmount;
    final isDeltaUp = (delta ?? 0) > 0;
    // less than previous = teal (store color), more = red
    final deltaColor = delta == null
        ? Colors.white38
        : isDeltaUp
            ? AppTheme.burnColor
            : AppTheme.storeColor;
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
          // ── Left: icon + label + amount + count ──
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
                      label,
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

          // ── Right: delta pill (bottom-aligned) ──
          if (delta != null && deltaIcon != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: deltaColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: deltaColor.withValues(alpha: 0.25),
                ),
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
    required this.currentDate,
    required this.period,
    required this.selectedType,
    required this.compare,
    required this.compareDate,
    required this.onCompareDateChanged,
  });

  final _PeriodData current;
  final DateTime currentDate;
  final _Period period;
  final TransactionType selectedType;
  final _PeriodData compare;
  final DateTime compareDate;
  final ValueChanged<DateTime> onCompareDateChanged;

  String _chipLabel() {
    switch (period) {
      case _Period.month:
        return DateFormat('MMM yyyy').format(compareDate);
      case _Period.year:
        return compareDate.year.toString();
      case _Period.overall:
        return 'N/A';
    }
  }

  Future<void> _openPicker(
      BuildContext context, VoidCallback Function(DateTime) apply) async {
    switch (period) {
      case _Period.month:
        if (!context.mounted) break;
        final picked = await showDialog<DateTime>(
          context: context,
          builder: (_) => _MonthPickerDialog(
            initial: compareDate,
            currentDate: currentDate,
          ),
        );
        if (picked != null) onCompareDateChanged(picked);
        break;
      case _Period.year:
        if (!context.mounted) break;
        final picked = await showDialog<int>(
          context: context,
          builder: (_) => _YearPickerDialog(
            initial: compareDate.year,
            currentYear: currentDate.year,
          ),
        );
        if (picked != null) onCompareDateChanged(DateTime(picked));
        break;
      case _Period.overall:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = current.totalFor(selectedType);
    final compareValue = compare.totalFor(selectedType);
    final selectedDelta = compareValue > 0
      ? (currentValue - compareValue) / compareValue * 100
        : null;
    final typeLabel = selectedType == TransactionType.burn ? 'Burn' : 'Store';

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _cardLabel('SPENDING COMPARISON'),
              const Spacer(),
              GestureDetector(
                onTap: () => _openPicker(context, (_) => () {}),
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
                    value: compareValue,
                    type: selectedType,
                    isCurrent: false,
                  ),
                ),
              ],
            ),
          ),
          if (selectedDelta != null) ...[
            const SizedBox(height: 10),
            Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DeltaChip(
                    label: typeLabel,
                    pct: selectedDelta,
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
          CurrencyFormatter.formatCompact(value),
          style: TextStyle(
            color: isCurrent
                ? (type == TransactionType.burn
                    ? AppTheme.burnColor
                    : AppTheme.storeColor)
                : (type == TransactionType.burn
                    ? AppTheme.burnColor.withValues(alpha: 0.45)
                    : AppTheme.storeColor.withValues(alpha: 0.45)),
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

// ─── Year picker dialog ───────────────────────────────────────────────────────

class _YearPickerDialog extends StatelessWidget {
  const _YearPickerDialog({
    required this.initial,
    required this.currentYear,
  });

  final int initial;
  /// The year currently viewed in reports — cannot be selected.
  final int currentYear;

  @override
  Widget build(BuildContext context) {
    // Show up to 12 selectable years before currentYear
    final years = List.generate(
        12, (i) => currentYear - 1 - i);
    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SELECT YEAR',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.6,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: years.length,
              itemBuilder: (_, i) {
                final year = years[i];
                final isSelected = year == initial;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, year),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$year',
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Month picker dialog ──────────────────────────────────────────────────────

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({
    required this.initial,
    required this.currentDate,
  });

  /// The month currently selected as comparison target.
  final DateTime initial;
  /// The month being viewed in reports — cannot be selected as compare target.
  final DateTime currentDate;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Year row ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.white70, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  '$_year',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: _year >= now.year
                      ? null
                      : () => setState(() => _year++),
                  icon: Icon(
                    Icons.chevron_right,
                    color:
                        _year >= now.year ? Colors.white24 : Colors.white70,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Month grid ─────────────────────────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: 12,
              itemBuilder: (_, i) {
                final month = i + 1;
                final dt = DateTime(_year, month, 1);
                final isFuture =
                    dt.isAfter(DateTime(now.year, now.month, 1));
                final isSameAsCurrent =
                    dt.year == widget.currentDate.year &&
                        dt.month == widget.currentDate.month;
                final isSelected = dt.year == widget.initial.year &&
                    dt.month == widget.initial.month;
                final disabled = isFuture || isSameAsCurrent;

                return GestureDetector(
                  onTap: disabled
                      ? null
                      : () => Navigator.pop(context, dt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : disabled
                              ? Colors.transparent
                              : AppTheme.bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white
                                .withValues(alpha: disabled ? 0.04 : 0.08),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat('MMM').format(dt),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : disabled
                                ? Colors.white24
                                : Colors.white70,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
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
      DateTime selectedDate, {
      TransactionType? typeFilter,
  }) {
    final now = selectedDate;
    final barType = typeFilter ?? TransactionType.burn;
    List<TransactionEntity> filtered;
    List<String> labels;
    List<double> values;
    String periodLabel;

    switch (period) {
      case _Period.month:
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        filtered = all
            .where((t) =>
                t.date.year == now.year && t.date.month == now.month)
            .toList();
        labels = List.generate(daysInMonth, (i) => '${i + 1}');
        values = List.generate(daysInMonth, (i) => filtered
            .where((t) =>
            t.type == barType && t.date.day == i + 1)
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
                    t.type == barType &&
                    t.date.month == m + 1)
                .fold(0.0, (s, t) => s + t.amount));
        periodLabel = now.year.toString();
        break;

      case _Period.overall:
        filtered = all.toList();
        labels = [];
        values = [];
        periodLabel = 'All Time';
        break;
    }

    if (typeFilter != null) {
      filtered = filtered.where((t) => t.type == typeFilter).toList();
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

  double totalFor(TransactionType type) {
    return type == TransactionType.burn ? totalBurn : totalStore;
  }

  int countFor(TransactionType type) {
    return type == TransactionType.burn ? burnCount : storeCount;
  }

  Map<CategoryEntity, double> breakdownFor(TransactionType type) {
    return type == TransactionType.burn ? burnBreakdown : storeBreakdown;
  }

  Map<CategoryEntity, double> parentBreakdownFor(TransactionType type) {
    return type == TransactionType.burn
        ? burnParentBreakdown
        : storeParentBreakdown;
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
