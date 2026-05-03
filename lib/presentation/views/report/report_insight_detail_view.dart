import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/custom_report_widget_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/presentation/providers/providers.dart';
import 'package:money_manager/presentation/views/add_transaction_view.dart';
import 'package:money_manager/presentation/views/report/report_burn_store_pie_card.dart';
import 'package:money_manager/presentation/views/report/report_custom_spend_card.dart';
import 'package:money_manager/presentation/views/report/report_insights_list_derived_data.dart';
import 'package:money_manager/presentation/views/report/report_monthly_savings_chart_card.dart';
import 'package:money_manager/presentation/views/report/report_period_data.dart';
import 'package:money_manager/presentation/views/report/report_portfolio_summary_panel.dart';
import 'package:money_manager/presentation/views/report/report_widgets.dart';
import 'package:money_manager/presentation/widgets/portfolio_balance_line_chart.dart';
import 'package:money_manager/presentation/widgets/spending_pie_chart.dart';
import 'package:money_manager/presentation/widgets/transaction_list_tile.dart';

/// Which Insights card the user opened.
enum ReportInsightSection {
  portfolio,
  monthlyBalance,
  burnVsStore,
  customTracked,
}

const double _kInsightHeroPortfolioChartH = 176;
const double _kInsightHeroSavingsChartH = 176;

Widget _reportInsightHeroGlow({required Widget child}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: AppTheme.primaryColor.withValues(alpha: 0.22),
          blurRadius: 48,
          spreadRadius: -12,
        ),
      ],
    ),
    child: child,
  );
}

class _MoreDetailSeparator extends StatelessWidget {
  const _MoreDetailSeparator();

  @override
  Widget build(BuildContext context) {
    Widget line() => Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        );
    return Row(
      children: [
        line(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'MORE DETAIL',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        line(),
      ],
    );
  }
}

Widget _insightHeroStack({required Widget mirroredCard}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _reportInsightHeroGlow(child: mirroredCard),
      const SizedBox(height: 22),
      const _MoreDetailSeparator(),
      const SizedBox(height: 12),
    ],
  );
}

Widget _mirroredInsightCard({
  required ReportInsightSection section,
  required ReportInsightsListDerivedData d,
}) {
  switch (section) {
    case ReportInsightSection.portfolio:
      return ReportPortfolioSummaryPanel(
        accountCount: d.accountCount,
        totalBalance: d.displayBalance,
        netChangeLabel: d.netLabel,
        netChangeDelta: d.netDelta,
        chartHeight: _kInsightHeroPortfolioChartH,
        chart: PortfolioBalanceLineChart(
          spots: d.portfolioSpots,
          minX: d.portfolioMinX,
          maxX: d.portfolioMaxX,
          bottomTitleInterval: d.portfolioBottomInterval,
          formatBottomTitle: d.portfolioBottomFormatter,
          compareSpots: d.monthCompareSpots,
        ),
        onTap: null,
      );
    case ReportInsightSection.monthlyBalance:
      return ReportMonthlySavingsChartCard(
        title: d.savCardTitle,
        chartHeight: _kInsightHeroSavingsChartH,
        chart: PortfolioBalanceLineChart(
          spots: d.savSpots,
          minX: d.savMinX,
          maxX: d.savMaxX,
          bottomTitleInterval: d.savInterval,
          formatBottomTitle: d.savBottomFormatter,
          lineColor: AppTheme.storeColor,
        ),
        onTap: null,
      );
    case ReportInsightSection.burnVsStore:
      return ReportBurnStorePieCard(
        title: 'BURN VS STORE',
        subtitle: d.pieSubtitle,
        burnTotal: d.burnTotal,
        storeTotal: d.storeTotal,
        largeHero: true,
      );
    case ReportInsightSection.customTracked:
      return const SizedBox.shrink();
  }
}

/// Full-screen drill-down: highlights, pies, and transactions for the selected insight.
class ReportInsightDetailView extends ConsumerStatefulWidget {
  const ReportInsightDetailView({
    super.key,
    required this.section,
    required this.initialPeriod,
    required this.initialSelectedDate,
    this.monthlyBalanceCardTitle,
    this.customWidgetId,
    this.customReportTitle,
  });

  final ReportInsightSection section;
  final ReportPeriod initialPeriod;
  final DateTime initialSelectedDate;

  /// Title from the list card (e.g. "MONTHLY BALANCE (LAST 6)").
  final String? monthlyBalanceCardTitle;

  /// When [section] is [ReportInsightSection.customTracked].
  final int? customWidgetId;

  /// App bar title when opening a custom report (e.g. widget name).
  final String? customReportTitle;

  @override
  ConsumerState<ReportInsightDetailView> createState() =>
      _ReportInsightDetailViewState();
}

class _ReportInsightDetailViewState extends ConsumerState<ReportInsightDetailView> {
  late ReportPeriod _period;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    _selectedDate = widget.initialSelectedDate;
  }

  void _onPeriodChanged(ReportPeriod p) {
    setState(() {
      _period = p;
      _selectedDate = DateTime.now();
    });
  }

  void _goBack() {
    setState(() {
      switch (_period) {
        case ReportPeriod.month:
          _selectedDate =
              DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
          break;
        case ReportPeriod.year:
          _selectedDate = DateTime(_selectedDate.year - 1);
          break;
        case ReportPeriod.overall:
          break;
      }
    });
  }

  void _goForward() {
    setState(() {
      switch (_period) {
        case ReportPeriod.month:
          _selectedDate =
              DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          break;
        case ReportPeriod.year:
          _selectedDate = DateTime(_selectedDate.year + 1);
          break;
        case ReportPeriod.overall:
          break;
      }
    });
  }

  String _periodLabel(DateTime now) {
    switch (_period) {
      case ReportPeriod.month:
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case ReportPeriod.year:
        return _selectedDate.year.toString();
      case ReportPeriod.overall:
        return 'All time';
    }
  }

  String _appBarTitle() {
    switch (widget.section) {
      case ReportInsightSection.portfolio:
        return 'Portfolio';
      case ReportInsightSection.monthlyBalance:
        return widget.monthlyBalanceCardTitle ?? 'Monthly balance';
      case ReportInsightSection.burnVsStore:
        return 'Burn vs store';
      case ReportInsightSection.customTracked:
        return widget.customReportTitle ?? 'Custom report';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final canGoNext = switch (_period) {
      ReportPeriod.month =>
        _selectedDate.year < now.year ||
            (_selectedDate.year == now.year &&
                _selectedDate.month < now.month),
      ReportPeriod.year => _selectedDate.year < now.year,
      ReportPeriod.overall => false,
    };

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _appBarTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: CompactReportPeriodHeader(
                period: _period,
                onPeriodChanged: _onPeriodChanged,
                dateLabel: _periodLabel(now),
                onPrev: _goBack,
                onNext: canGoNext ? _goForward : null,
                showNavigator: _period != ReportPeriod.overall,
              ),
            ),
            Expanded(
              child: _Body(
                section: widget.section,
                period: _period,
                selectedDate: _selectedDate,
                now: now,
                monthlyBalanceCardTitle: widget.monthlyBalanceCardTitle,
                customWidgetId: widget.customWidgetId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    required this.section,
    required this.period,
    required this.selectedDate,
    required this.now,
    this.monthlyBalanceCardTitle,
    this.customWidgetId,
  });

  final ReportInsightSection section;
  final ReportPeriod period;
  final DateTime selectedDate;
  final DateTime now;
  final String? monthlyBalanceCardTitle;
  final int? customWidgetId;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  /// Matches main report: `false` = parent categories, `true` = subcategories in pies.
  bool _showPieSubcategories = false;

  static Map<CategoryEntity, double> _topCategories(
    Map<CategoryEntity, double> source,
    int maxEntries,
  ) {
    if (source.length <= maxEntries) return Map.from(source);
    final entries = source.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries.take(maxEntries));
  }

  static TransactionEntity? _largestOf(
    Iterable<TransactionEntity> rows,
    bool Function(TransactionEntity t) pred,
  ) {
    TransactionEntity? best;
    var bestAmt = 0.0;
    for (final t in rows) {
      if (!pred(t)) continue;
      if (t.amount > bestAmt) {
        bestAmt = t.amount;
        best = t;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final period = widget.period;
    final selectedDate = widget.selectedDate;
    final now = widget.now;
    final monthlyBalanceCardTitle = widget.monthlyBalanceCardTitle;
    final customWidgetId = widget.customWidgetId;

    final txAsync = ref.watch(transactionListProvider);
    final catAsync = ref.watch(categoryListProvider);
    final accAsync = ref.watch(accountListProvider);
    final customAsync = ref.watch(customReportWidgetListProvider);

    return txAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (e, _) => Center(
        child: Text(
          e.toString(),
          style: const TextStyle(color: AppTheme.burnColor),
        ),
      ),
      data: (transactions) {
        return catAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
          error: (e, _) => Center(
            child: Text(
              e.toString(),
              style: const TextStyle(color: AppTheme.burnColor),
            ),
          ),
          data: (categories) {
            if (section == ReportInsightSection.customTracked) {
              return customAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
                error: (e, s) => const Center(
                  child: Text(
                    'Could not load report',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
                data: (widgets) {
                  CustomReportWidgetEntity? entity;
                  for (final e in widgets) {
                    if (e.id == customWidgetId) {
                      entity = e;
                      break;
                    }
                  }
                  if (entity == null) {
                    return const Center(
                      child: Text(
                        'This report was removed.',
                        style: TextStyle(color: Colors.white38),
                      ),
                    );
                  }
                  final custom = entity;
                  final pd = PeriodData.compute(
                    transactions,
                    categories,
                    period,
                    selectedDate,
                    typeFilter: custom.typeFilter,
                    categoryIdFilter: custom.categoryFilterIds.toSet(),
                    showSubcategories: custom.showSubcategories,
                  );
                  final hero = _insightHeroStack(
                    mirroredCard: ReportCustomSpendCard(
                      entity: custom,
                      transactions: transactions,
                      period: period,
                      selectedDate: selectedDate,
                      now: now,
                      onDelete: () async {
                        await ref
                            .read(customReportWidgetRepositoryProvider)
                            .delete(custom.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      onEdit: null,
                      showDragHandle: false,
                      chartSectionHeight: _kInsightHeroSavingsChartH,
                    ),
                  );
                  return _buildScrollable(
                    context,
                    insightHero: hero,
                    title: 'Category breakdown & transactions',
                    periodData: pd,
                    pieCenterLabel: switch (custom.typeFilter) {
                      TransactionType.burn => 'Burn',
                      TransactionType.store => 'Saved',
                      TransactionType.income => 'Income',
                      _ => 'Total',
                    },
                    pieMap: _topCategories(
                      _showPieSubcategories
                          ? pd.breakdownFor(custom.typeFilter)
                          : pd.parentBreakdownFor(custom.typeFilter),
                      10,
                    ),
                    highlights: _highlightsForType(
                      pd.transactions,
                      custom.typeFilter,
                    ),
                    pieViewDrillToggle: true,
                  );
                },
              );
            }

            return accAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
              error: (e, _) => Center(
                child: Text(
                  e.toString(),
                  style: const TextStyle(color: AppTheme.burnColor),
                ),
              ),
              data: (accounts) {
                final derived = ReportInsightsListDerivedData.compute(
                  transactions: transactions,
                  accounts: accounts,
                  period: period,
                  selectedDate: selectedDate,
                  now: now,
                );
                final hero = _insightHeroStack(
                  mirroredCard: _mirroredInsightCard(
                    section: section,
                    d: derived,
                  ),
                );

                switch (section) {
                  case ReportInsightSection.customTracked:
                    return const SizedBox.shrink();
                  case ReportInsightSection.portfolio:
                    final pd = PeriodData.compute(
                      transactions,
                      categories,
                      period,
                      selectedDate,
                    );
                    return _buildScrollable(
                      context,
                      insightHero: hero,
                      title:
                          'All activity in ${_periodSubtitle(period, selectedDate)}',
                      periodData: pd,
                      extra: _TypeTotalsPie(
                        burn: pd.totalBurn,
                        store: pd.totalStore,
                        income: pd.totalIncome,
                      ),
                      pieCenterLabel: 'Types',
                      pieMap: const {},
                      highlights: _highlightsAllTypes(pd.transactions),
                    );
                  case ReportInsightSection.monthlyBalance:
                    final pd = PeriodData.compute(
                      transactions,
                      categories,
                      period,
                      selectedDate,
                    );
                    final storeTx = pd.transactions
                        .where((t) => t.type == TransactionType.store);
                    return _buildScrollable(
                      context,
                      insightHero: hero,
                      title:
                          monthlyBalanceCardTitle ?? 'Stored this period',
                      periodData: pd,
                      pieCenterLabel: 'By category',
                      pieMap: _topCategories(
                        _showPieSubcategories
                            ? pd.breakdownFor(TransactionType.store)
                            : pd.parentBreakdownFor(TransactionType.store),
                        10,
                      ),
                      highlights: [
                        if (_largestOf(storeTx, (_) => true) != null)
                          _Highlight(
                            label: 'Largest save',
                            transaction: _largestOf(storeTx, (_) => true)!,
                          ),
                      ],
                      listFilter: (t) => t.type == TransactionType.store,
                      pieViewDrillToggle: true,
                    );
                  case ReportInsightSection.burnVsStore:
                    final pd = PeriodData.compute(
                      transactions,
                      categories,
                      period,
                      selectedDate,
                    );
                    return _buildScrollable(
                      context,
                      insightHero: hero,
                      title:
                          'Burn and store in ${_periodSubtitle(period, selectedDate)}',
                      periodData: pd,
                      pieCenterLabel: 'Burn by category',
                      pieMap: _topCategories(
                        _showPieSubcategories
                            ? pd.breakdownFor(TransactionType.burn)
                            : pd.parentBreakdownFor(TransactionType.burn),
                        10,
                      ),
                      secondPieLabel: 'Store by category',
                      secondPieMap: _topCategories(
                        _showPieSubcategories
                            ? pd.breakdownFor(TransactionType.store)
                            : pd.parentBreakdownFor(TransactionType.store),
                        10,
                      ),
                      highlights: [
                        if (_largestOf(
                              pd.transactions,
                              (t) => t.type == TransactionType.burn,
                            ) !=
                            null)
                          _Highlight(
                            label: 'Largest burn',
                            transaction: _largestOf(
                              pd.transactions,
                              (t) => t.type == TransactionType.burn,
                            )!,
                          ),
                        if (_largestOf(
                              pd.transactions,
                              (t) => t.type == TransactionType.store,
                            ) !=
                            null)
                          _Highlight(
                            label: 'Largest save',
                            transaction: _largestOf(
                              pd.transactions,
                              (t) => t.type == TransactionType.store,
                            )!,
                          ),
                      ],
                      listFilter: (t) =>
                          t.type == TransactionType.burn ||
                          t.type == TransactionType.store,
                      pieViewDrillToggle: true,
                    );
                }
              },
            );
          },
        );
      },
    );
  }

  String _periodSubtitle(ReportPeriod p, DateTime d) {
    switch (p) {
      case ReportPeriod.month:
        return DateFormat('MMMM yyyy').format(d);
      case ReportPeriod.year:
        return '${d.year}';
      case ReportPeriod.overall:
        return 'All time';
    }
  }

  List<Widget> _highlightsForType(
    List<TransactionEntity> txns,
    TransactionType type,
  ) {
    bool pred(TransactionEntity t) => t.type == type;
    final best = _largestOf(txns, pred);
    if (best == null) return [];
    final label = switch (type) {
      TransactionType.burn => 'Largest burn',
      TransactionType.store => 'Largest save',
      TransactionType.income => 'Largest income',
      _ => 'Largest amount',
    };
    return [_Highlight(label: label, transaction: best)];
  }

  List<Widget> _highlightsAllTypes(List<TransactionEntity> txns) {
    final out = <Widget>[];
    final burn = _largestOf(txns, (t) => t.type == TransactionType.burn);
    final store = _largestOf(txns, (t) => t.type == TransactionType.store);
    final income = _largestOf(txns, (t) => t.type == TransactionType.income);
    if (burn != null) {
      out.add(_Highlight(label: 'Largest burn', transaction: burn));
    }
    if (store != null) {
      out.add(_Highlight(label: 'Largest save', transaction: store));
    }
    if (income != null) {
      out.add(_Highlight(label: 'Largest income', transaction: income));
    }
    return out;
  }

  Widget _buildScrollable(
    BuildContext context, {
    Widget? insightHero,
    required String title,
    required PeriodData periodData,
    required String pieCenterLabel,
    required Map<CategoryEntity, double> pieMap,
    List<Widget> highlights = const [],
    Widget? extra,
    String? secondPieLabel,
    Map<CategoryEntity, double>? secondPieMap,
    bool Function(TransactionEntity t)? listFilter,
    bool pieViewDrillToggle = false,
  }) {
    final filteredList = listFilter == null
        ? periodData.transactions
        : periodData.transactions.where(listFilter).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (insightHero != null) ...[
                insightHero,
              ],
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (highlights.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...highlights,
              ],
              if (extra != null) ...[
                const SizedBox(height: 12),
                extra,
              ],
              if (pieViewDrillToggle &&
                  (pieMap.isNotEmpty ||
                      (secondPieMap != null && secondPieMap.isNotEmpty))) ...[
                DrillToggle(
                  showSubcategories: _showPieSubcategories,
                  onChanged: (v) => setState(() => _showPieSubcategories = v),
                ),
                const SizedBox(height: 14),
              ],
              if (pieMap.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  !pieViewDrillToggle
                      ? (secondPieMap != null
                          ? 'Categories (burn)'
                          : 'By category')
                      : (secondPieMap != null
                          ? (_showPieSubcategories
                              ? 'Subcategories (burn)'
                              : 'Categories (burn)')
                          : (_showPieSubcategories
                              ? 'By subcategory'
                              : 'By category')),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                SpendingPieChart(
                  data: pieMap,
                  centerLabel: pieCenterLabel,
                ),
              ],
              if (secondPieMap != null && secondPieMap.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  !pieViewDrillToggle
                      ? (secondPieLabel ?? 'By category')
                      : (_showPieSubcategories
                          ? 'Store by subcategory'
                          : 'Store by category'),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                SpendingPieChart(
                  data: secondPieMap,
                  centerLabel: 'Saved',
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Transactions (${filteredList.length})',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
        if (filteredList.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
              child: Center(
                child: Text(
                  'No matching transactions',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final t = filteredList[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: TransactionListTile(
                      transaction: t,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddTransactionView(existing: t),
                        ),
                      ),
                    ),
                  );
                },
                childCount: filteredList.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.label,
    required this.transaction,
  });

  final String label;
  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final cat = transaction.category;
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddTransactionView(existing: transaction),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cat?.name ?? 'Uncategorized',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (transaction.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        transaction.note.trim(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(transaction.amount),
                style: TextStyle(
                  color: transaction.isBurn
                      ? AppTheme.burnColor
                      : transaction.isIncome
                          ? AppTheme.incomeColor
                          : AppTheme.storeColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeTotalsPie extends StatefulWidget {
  const _TypeTotalsPie({
    required this.burn,
    required this.store,
    required this.income,
  });

  final double burn;
  final double store;
  final double income;

  @override
  State<_TypeTotalsPie> createState() => _TypeTotalsPieState();
}

class _TypeTotalsPieState extends State<_TypeTotalsPie> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final burn = widget.burn;
    final store = widget.store;
    final income = widget.income;
    final total = burn + store + income;
    if (total <= 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No burn, store, or income in this period',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      );
    }

    final sections = <PieChartSectionData>[];
    void add(double v, Color color, String name) {
      if (v <= 0) return;
      final i = sections.length;
      final pct = v / total * 100;
      final touched = _touched == i;
      sections.add(
        PieChartSectionData(
          value: v,
          color: color,
          radius: touched ? 48 : 42,
          title: touched ? '${pct.toStringAsFixed(1)}%' : '',
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      );
    }

    add(burn, AppTheme.burnColor, 'Burn');
    add(store, AppTheme.storeColor, 'Store');
    add(income, AppTheme.incomeColor, 'Income');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BY TYPE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 136,
                height: 136,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response?.touchedSection == null) {
                            _touched = null;
                            return;
                          }
                          _touched =
                              response!.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    centerSpaceRadius: 34,
                    centerSpaceColor: AppTheme.cardColor,
                    sectionsSpace: 2,
                    sections: sections,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (burn > 0) _Legend('Burn', AppTheme.burnColor, burn, total),
                    if (burn > 0 && (store > 0 || income > 0))
                      const SizedBox(height: 10),
                    if (store > 0)
                      _Legend('Store', AppTheme.storeColor, store, total),
                    if (store > 0 && income > 0) const SizedBox(height: 10),
                    if (income > 0)
                      _Legend('Income', AppTheme.incomeColor, income, total),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color, this.amount, this.total);

  final String label;
  final Color color;
  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? amount / total * 100 : 0.0;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${pct.toStringAsFixed(0)}%',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
