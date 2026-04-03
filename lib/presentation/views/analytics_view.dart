import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/presentation/providers/providers.dart';
import 'package:money_manager/presentation/widgets/bento_card.dart';
import 'package:money_manager/presentation/widgets/spending_pie_chart.dart';
import 'package:money_manager/presentation/widgets/weekly_bar_chart.dart';

class AnalyticsView extends ConsumerStatefulWidget {
  const AnalyticsView({super.key});

  @override
  ConsumerState<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends ConsumerState<AnalyticsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Burn'),
            Tab(text: 'Store'),
          ],
        ),
      ),
      body: analyticsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: AppTheme.burnColor)),
        ),
        data: (analytics) => TabBarView(
          controller: _tabController,
          children: [
            _AnalyticsTab(
              type: TransactionType.burn,
              total: analytics.totalBurn,
              monthlyTotal: analytics.monthlyBurn,
              delta: analytics.delta,
              weeklyData: analytics.weeklySpend,
              breakdown: analytics.burnCategoryBreakdown,
            ),
            _AnalyticsTab(
              type: TransactionType.store,
              total: analytics.totalStore,
              monthlyTotal: 0,
              delta: 0,
              weeklyData: List.filled(7, 0),
              breakdown: analytics.storeCategoryBreakdown,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({
    required this.type,
    required this.total,
    required this.monthlyTotal,
    required this.delta,
    required this.weeklyData,
    required this.breakdown,
  });

  final TransactionType type;
  final double total;
  final double monthlyTotal;
  final double delta;
  final List<double> weeklyData;
  final Map<CategoryEntity, double> breakdown;

  Color get _accentColor =>
      type == TransactionType.burn ? AppTheme.burnColor : AppTheme.storeColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Summary Card ──────────────────────────────────────────────────
          BentoCard(
            gradient: LinearGradient(
              colors: [
                _accentColor.withValues(alpha: 0.3),
                AppTheme.cardColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ALL-TIME ${type.label.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(total),
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (type == TransactionType.burn)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Weekly Delta',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      DeltaBadge(delta: delta),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Weekly Bar Chart ──────────────────────────────────────────────
          if (type == TransactionType.burn) ...[
            BentoCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WEEKLY TREND',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: WeeklyBarChart(weeklyData: weeklyData),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ─── Pie Chart ────────────────────────────────────────────────────
          if (breakdown.isNotEmpty) ...[
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BY CATEGORY',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SpendingPieChart(data: breakdown),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Category Progress Bars ────────────────────────────────────
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CATEGORY BREAKDOWN',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...breakdown.entries.map((entry) => _CategoryProgress(
                        category: entry.key,
                        amount: entry.value,
                        total: total,
                      )),
                ],
              ),
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.pie_chart_outline_rounded,
                        color: Colors.white24, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'No ${type.label.toLowerCase()} data yet',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryProgress extends StatelessWidget {
  const _CategoryProgress({
    required this.category,
    required this.amount,
    required this.total,
  });

  final CategoryEntity category;
  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (amount / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(category.icon, color: category.color, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                CurrencyFormatter.formatCompact(amount),
                style: TextStyle(
                  color: category.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(pct * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(category.color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
