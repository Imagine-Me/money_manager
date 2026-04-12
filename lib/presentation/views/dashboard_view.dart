import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';
import 'package:money_manager/domain/entities/report_filter_entity.dart';
import 'package:money_manager/presentation/providers/providers.dart';
import 'package:money_manager/presentation/views/report_detail_view.dart';
import 'package:money_manager/presentation/views/report_list_view.dart';
import 'package:money_manager/presentation/views/transactions_view.dart';
import 'package:money_manager/presentation/widgets/bento_card.dart';
import 'package:money_manager/presentation/widgets/spending_pie_chart.dart';
import 'package:money_manager/presentation/widgets/transaction_list_tile.dart';
import 'package:money_manager/presentation/widgets/weekly_bar_chart.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final filtersAsync = ref.watch(reportFilterListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 4),

                  // ─── Row 1: Total Balance (full-width) ─────────────────────
                  analyticsAsync.when(
                    loading: () => _BalanceSkeleton(),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                    data: (analytics) => _BalanceCard(analytics: analytics),
                  ),
                  const SizedBox(height: 12),

                  // ─── Row 2: Burn + Store (half + half) ─────────────────────
                  analyticsAsync.when(
                    loading: () => Row(children: [
                      Expanded(child: _SkeletonBox(height: 100)),
                      const SizedBox(width: 12),
                      Expanded(child: _SkeletonBox(height: 100)),
                    ]),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (analytics) => Row(
                      children: [
                        Expanded(
                          child: StatBentoCard(
                            label: 'BURN',
                            value: CurrencyFormatter.formatCompact(
                                analytics.monthlyBurn),
                            icon: Icons.local_fire_department_rounded,
                            iconColor: AppTheme.burnColor,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.burnColor.withValues(alpha: 0.25),
                                AppTheme.cardColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            subtitle: Text(
                              'Expenditure',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatBentoCard(
                            label: 'STORE',
                            value: CurrencyFormatter.formatCompact(
                                analytics.monthlyStore),
                            icon: Icons.savings_rounded,
                            iconColor: AppTheme.storeColor,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.storeColor.withValues(alpha: 0.25),
                                AppTheme.cardColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            subtitle: Text(
                              'Savings',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── Quick Filter Presets ──────────────────────────────
                  filtersAsync.whenData((filters) => filters).valueOrNull
                              ?.isNotEmpty ==
                          true
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QUICK REPORTS',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: filtersAsync.valueOrNull!
                                    .map((f) => Padding(
                                          padding: const EdgeInsets.only(
                                              right: 8),
                                          child: _FilterPresetChip(
                                            filter: f,
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ReportDetailView(
                                                          entity: f),
                                                ),
                                              );
                                            },
                                            onDelete: () async {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  backgroundColor:
                                                      const Color(0xFF1E1E2E),
                                                  title: const Text(
                                                    'Delete preset?',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16),
                                                  ),
                                                  content: Text(
                                                    'Remove "${f.name}"?',
                                                    style: const TextStyle(
                                                        color: Colors.white60),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child: const Text(
                                                          'Cancel',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white38)),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: const Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                              color: Color(
                                                                  0xFFFF6B6B))),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                await ref
                                                    .read(
                                                        reportFilterRepositoryProvider)
                                                    .delete(f.id);
                                              }
                                            },
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        )
                      : const SizedBox.shrink(),

                  // ─── Row 3: Weekly Chart (full-width) ─────────────────────
                  analyticsAsync.when(
                    loading: () => _SkeletonBox(height: 180),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (analytics) => BentoCard(
                      height: 190,
                      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WEEKLY SPEND',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: WeeklyBarChart(
                              weeklyData: analytics.weeklySpend,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── Row 4: Category Pie Chart (full-width) ────────────────
                  analyticsAsync.when(
                    loading: () => _SkeletonBox(height: 220),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (analytics) =>
                        analytics.monthlyBurnParentBreakdown.isNotEmpty
                            ? BentoCard(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionHeader(
                                        title: 'SPEND BREAKDOWN',
                                      action: 'Report',
                                      onTap: () => _goToReports(context)),
                                    const SizedBox(height: 16),
                                    SpendingPieChart(
                                      data: analytics.monthlyBurnParentBreakdown,
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),

                  // ─── Row 5: Recent Transactions ────────────────────────────
                  BentoCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: 'RECENT',
                          action: 'See all',
                          onTap: () => _goToTransactions(context),
                        ),
                        const SizedBox(height: 8),
                        analyticsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          error: (e, _) => _ErrorCard(message: e.toString()),
                          data: (analytics) {
                            final recent =
                                analytics.monthlyTransactions.take(5).toList();
                            if (recent.isEmpty) {
                              return _EmptyState(
                                icon: Icons.receipt_long_rounded,
                                message:
                                    'No transactions this month.\nTap + to add one!',
                              );
                            }
                            return Column(
                              children: recent
                                  .map((tx) => TransactionListTile(
                                        transaction: tx,
                                        onDelete: () => ref
                                            .read(transactionRepositoryProvider)
                                            .delete(tx.id),
                                      ))
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppTheme.bgColor,
      surfaceTintColor: Colors.transparent,
      expandedHeight: 80,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.storeColor],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 18),
                ),

              ],
            ),
            Row(
              children: [
                _IconBtn(
                  icon: Icons.list_alt_rounded,
                  onTap: () => _goToTransactions(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _goToTransactions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransactionsView()),
    );
  }

  void _goToReports(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReportListView()),
    );
  }
}

// ─── Small helper widgets ──────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.analytics});

  final AppAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = _monthName(now.month);

    // % change helpers
    double _pct(double current, double prev) =>
        prev == 0 ? 0 : ((current - prev) / prev) * 100;

    final burnDelta = _pct(analytics.monthlyBurn, analytics.prevMonthlyBurn);
    final storeDelta = _pct(analytics.monthlyStore, analytics.prevMonthlyStore);

    return BentoCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF2A1F6E), Color(0xFF1A1A3A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$monthLabel OVERVIEW',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          // Burn (left) | Store (right)
          IntrinsicHeight(
            child: Row(
              children: [
                // Burn
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.local_fire_department_rounded,
                              color: AppTheme.burnColor, size: 14),
                          SizedBox(width: 4),
                          Text('BURN',
                              style: TextStyle(
                                  color: AppTheme.burnColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(analytics.monthlyBurn),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _MiniDelta(delta: burnDelta, higherIsBad: true),
                    ],
                  ),
                ),
                // Divider
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white10,
                ),
                // Store
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.savings_rounded,
                              color: AppTheme.storeColor, size: 14),
                          SizedBox(width: 4),
                          Text('STORE',
                              style: TextStyle(
                                  color: AppTheme.storeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(analytics.monthlyStore),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _MiniDelta(delta: storeDelta, higherIsBad: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'vs last month',
            style: const TextStyle(color: Colors.white24, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC'
    ];
    return names[month - 1];
  }
}


class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}

class _MiniDelta extends StatelessWidget {
  const _MiniDelta({required this.delta, required this.higherIsBad});

  final double delta;
  final bool higherIsBad;

  @override
  Widget build(BuildContext context) {
    if (delta == 0) {
      return const Text('—',
          style: TextStyle(color: Colors.white38, fontSize: 11));
    }
    final isUp = delta > 0;
    // for burn: up = bad (red), down = good (green)
    // for store: up = good (green), down = bad (red)
    final isGood = higherIsBad ? !isUp : isUp;
    final color = isGood ? AppTheme.storeColor : AppTheme.burnColor;
    final icon = isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 11),
        Text(
          '${delta.abs().toStringAsFixed(1)}%',
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _BalanceSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkeletonBox(height: 110);
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: Colors.white24, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      color: AppTheme.burnColor.withValues(alpha: 0.1),
      child: Text(
        'Error: $message',
        style: const TextStyle(color: AppTheme.burnColor, fontSize: 13),
      ),
    );
  }
}

// ─── Filter preset chip ───────────────────────────────────────────────────────

class _FilterPresetChip extends StatelessWidget {
  const _FilterPresetChip({
    required this.filter,
    required this.onTap,
    required this.onDelete,
  });

  final ReportFilterEntity filter;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_rounded,
                color: AppTheme.primaryColor, size: 12),
            const SizedBox(width: 6),
            Text(
              filter.name,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
