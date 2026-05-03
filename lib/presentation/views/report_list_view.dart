import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/presentation/providers/providers.dart';
import 'package:money_manager/presentation/views/report/report_burn_store_pie_card.dart';
import 'package:money_manager/presentation/views/report/report_custom_widgets_section.dart';
import 'package:money_manager/presentation/views/report/report_insight_detail_view.dart';
import 'package:money_manager/presentation/views/report/report_insights_list_derived_data.dart';
import 'package:money_manager/presentation/views/report/report_monthly_savings_chart_card.dart';
import 'package:money_manager/presentation/views/report/report_period_data.dart';
import 'package:money_manager/presentation/views/report/report_portfolio_summary_panel.dart';
import 'package:money_manager/presentation/views/report/report_widgets.dart';
import 'package:money_manager/presentation/widgets/portfolio_balance_line_chart.dart';

class ReportListView extends ConsumerStatefulWidget {
  const ReportListView({super.key});

  @override
  ConsumerState<ReportListView> createState() => _ReportListViewState();
}

class _ReportListViewState extends ConsumerState<ReportListView> {
  ReportPeriod _period = ReportPeriod.month;
  DateTime _selectedDate = DateTime.now();

  void _onPeriodChanged(ReportPeriod p) {
    setState(() {
      final n = DateTime.now();
      _period = p;
      _selectedDate = n;
    });
  }

  void _goBack() {
    setState(() {
      switch (_period) {
        case ReportPeriod.month:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
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
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          break;
        case ReportPeriod.year:
          _selectedDate = DateTime(_selectedDate.year + 1);
          break;
        case ReportPeriod.overall:
          break;
      }
    });
  }

  String _periodLabel() {
    switch (_period) {
      case ReportPeriod.month:
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case ReportPeriod.year:
        return _selectedDate.year.toString();
      case ReportPeriod.overall:
        return 'All time';
    }
  }

  void _openInsightDetail(
    BuildContext context, {
    required ReportInsightSection section,
    String? monthlyBalanceCardTitle,
    int? customWidgetId,
    String? customReportTitle,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportInsightDetailView(
          section: section,
          initialPeriod: _period,
          initialSelectedDate: _selectedDate,
          monthlyBalanceCardTitle: monthlyBalanceCardTitle,
          customWidgetId: customWidgetId,
          customReportTitle: customReportTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionListProvider);
    final accAsync = ref.watch(accountListProvider);
    final now = DateTime.now();

    final canGoNext = switch (_period) {
      ReportPeriod.month =>
        _selectedDate.year < now.year ||
            (_selectedDate.year == now.year && _selectedDate.month < now.month),
      ReportPeriod.year => _selectedDate.year < now.year,
      ReportPeriod.overall => false,
    };

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: CompactReportPeriodHeader(
                period: _period,
                onPeriodChanged: _onPeriodChanged,
                dateLabel: _periodLabel(),
                onPrev: _goBack,
                onNext: canGoNext ? _goForward : null,
                showNavigator: _period != ReportPeriod.overall,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: txAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      e.toString(),
                      style: const TextStyle(color: AppTheme.burnColor),
                    ),
                  ),
                ),
                data: (transactions) {
                  return accAsync.when(
                    loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        e.toString(),
                        style: const TextStyle(color: AppTheme.burnColor),
                      ),
                    ),
                    data: (accounts) {
                      final d = ReportInsightsListDerivedData.compute(
                        transactions: transactions,
                        accounts: accounts,
                        period: _period,
                        selectedDate: _selectedDate,
                        now: now,
                      );

                      const chartH = 128.0;
                      const savingsChartH = 128.0;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ReportPortfolioSummaryPanel(
                              accountCount: d.accountCount,
                              totalBalance: d.displayBalance,
                              netChangeLabel: d.netLabel,
                              netChangeDelta: d.netDelta,
                              chartHeight: chartH,
                              chart: PortfolioBalanceLineChart(
                                spots: d.portfolioSpots,
                                minX: d.portfolioMinX,
                                maxX: d.portfolioMaxX,
                                bottomTitleInterval: d.portfolioBottomInterval,
                                formatBottomTitle: d.portfolioBottomFormatter,
                                compareSpots: d.monthCompareSpots,
                              ),
                              onTap: () => _openInsightDetail(
                                context,
                                section: ReportInsightSection.portfolio,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ReportMonthlySavingsChartCard(
                              title: d.savCardTitle,
                              chartHeight: savingsChartH,
                              chart: PortfolioBalanceLineChart(
                                spots: d.savSpots,
                                minX: d.savMinX,
                                maxX: d.savMaxX,
                                bottomTitleInterval: d.savInterval,
                                formatBottomTitle: d.savBottomFormatter,
                                lineColor: AppTheme.storeColor,
                              ),
                              onTap: () => _openInsightDetail(
                                context,
                                section: ReportInsightSection.monthlyBalance,
                                monthlyBalanceCardTitle: d.savCardTitle,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ReportBurnStorePieCard(
                              title: 'BURN VS STORE',
                              subtitle: d.pieSubtitle,
                              burnTotal: d.burnTotal,
                              storeTotal: d.storeTotal,
                              onTap: () => _openInsightDetail(
                                context,
                                section: ReportInsightSection.burnVsStore,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ReportCustomWidgetsSection(
                              period: _period,
                              selectedDate: _selectedDate,
                              now: now,
                              transactions: transactions,
                              onCustomReportTap: (e) => _openInsightDetail(
                                context,
                                section: ReportInsightSection.customTracked,
                                customWidgetId: e.id,
                                customReportTitle: e.name,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
