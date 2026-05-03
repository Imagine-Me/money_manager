import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/presentation/providers/providers.dart';
import 'package:money_manager/presentation/views/report/report_period_data.dart';
import 'package:money_manager/presentation/views/report/report_burn_store_pie_card.dart';
import 'package:money_manager/presentation/views/report/report_custom_widgets_section.dart';
import 'package:money_manager/presentation/views/report/report_monthly_savings_chart_card.dart';
import 'package:money_manager/presentation/views/report/report_portfolio_balance.dart';
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
                      final combined = accounts.fold(
                          0.0, (s, a) => s + a.balance);
                      final newestFirst = List<TransactionEntity>.of(transactions)
                        ..sort((a, b) => b.date.compareTo(a.date));

                      var spots = <FlSpot>[];
                      var minX = 1.0;
                      var maxX = 1.0;
                      var bottomInterval = 1.0;
                      String Function(double x)? bottomFormatter;
                      List<FlSpot>? monthCompareSpots;

                      var displayBalance = combined;
                      var netDelta = 0.0;
                      var netLabel = '';

                      switch (_period) {
                        case ReportPeriod.month:
                          final daysInMonth =
                              daysInSelectedMonth(_selectedDate);
                          spots = monthlyBalanceSpots(
                            newestFirst: newestFirst,
                            month: _selectedDate,
                            combinedBalanceNow: combined,
                            now: now,
                          );
                          final prevMonthStart = DateTime(
                            _selectedDate.year,
                            _selectedDate.month - 1,
                            1,
                          );
                          final prevMonthSpots = monthlyBalanceSpots(
                            newestFirst: newestFirst,
                            month: prevMonthStart,
                            combinedBalanceNow: combined,
                            now: now,
                          );
                          monthCompareSpots = spots.isEmpty
                              ? null
                              : prevMonthSpots.isEmpty
                                  ? null
                                  : prevMonthSpots;
                          minX = 1;
                          maxX = daysInMonth.toDouble();
                          if (spots.isNotEmpty) {
                            maxX = math.max(maxX, spots.last.x);
                          }
                          if (prevMonthSpots.isNotEmpty) {
                            maxX = math.max(maxX, prevMonthSpots.last.x);
                          }
                          bottomInterval =
                              niceBottomInterval(maxX.round()).toDouble();
                          bottomFormatter = null;

                          displayBalance = balanceAtEndOfSelectedMonth(
                            newestFirst: newestFirst,
                            selectedMonth: _selectedDate,
                            combinedBalanceNow: combined,
                            now: now,
                          );
                          netDelta = netChangeInSelectedMonth(
                            newestFirst: newestFirst,
                            selectedMonth: _selectedDate,
                            combinedBalanceNow: combined,
                            now: now,
                          );
                          final isSelCurrent = _selectedDate.year == now.year &&
                              _selectedDate.month == now.month;
                          netLabel = isSelCurrent
                              ? 'Saved this month'
                              : 'Net in ${DateFormat('MMMM yyyy').format(_selectedDate)}';
                          break;
                        case ReportPeriod.year:
                          monthCompareSpots = null;
                          spots = yearlyBalanceSpots(
                            newestFirst: newestFirst,
                            year: _selectedDate.year,
                            combinedBalanceNow: combined,
                            now: now,
                          );
                          minX = 1;
                          maxX = spots.isEmpty ? 1 : spots.last.x;
                          bottomInterval = 1;
                          bottomFormatter = (x) => DateFormat('MMM').format(
                              DateTime(_selectedDate.year, x.round(), 1));

                          displayBalance = balanceAtEndOfSelectedYear(
                            newestFirst: newestFirst,
                            year: _selectedDate.year,
                            combinedBalanceNow: combined,
                            now: now,
                          );
                          netDelta = netChangeInSelectedYear(
                            newestFirst: newestFirst,
                            year: _selectedDate.year,
                            combinedBalanceNow: combined,
                            now: now,
                          );
                          netLabel = 'Net in ${_selectedDate.year}';
                          break;
                        case ReportPeriod.overall:
                          monthCompareSpots = null;
                          final points = overallBalancePoints(
                            newestFirst: newestFirst,
                            anchor: DateTime(now.year, now.month, 1),
                            combinedBalanceNow: combined,
                            now: now,
                          );
                          spots = [
                            for (var i = 0; i < points.length; i++)
                              FlSpot((i + 1).toDouble(), points[i].y),
                          ];
                          minX = 1;
                          maxX = spots.isEmpty ? 1 : spots.last.x;
                          bottomInterval = 3;
                          bottomFormatter = (x) {
                            final i = x.round() - 1;
                            if (i < 0 || i >= points.length) return '';
                            return DateFormat('MMM yy')
                                .format(points[i].monthStart);
                          };

                          displayBalance = combined;
                          netDelta = points.length >= 2
                              ? points.last.y - points.first.y
                              : 0;
                          netLabel = 'Net (24 months)';
                          break;
                      }

                      const chartH = 128.0;
                      const savingsChartH = 128.0;

                      var savSpots = <FlSpot>[];
                      var savMinX = 1.0;
                      var savMaxX = 6.0;
                      var savInterval = 1.0;
                      String Function(double x)? savBottomFormatter;
                      var savCardTitle = 'MONTHLY BALANCE';

                      switch (_period) {
                        case ReportPeriod.month:
                          final savMonths = filteredLastSixTransactionMonths(
                            allTransactions: transactions,
                            selectedMonthAny: _selectedDate,
                          );
                          savSpots = monthlySavingsSpotsForMonths(
                            monthStartsOldestFirst: savMonths,
                            newestFirst: newestFirst,
                            combinedBalanceNow: combined,
                            now: now,
                          );
                          savMinX = 1;
                          savMaxX =
                              savSpots.isEmpty ? 1 : savSpots.last.x;
                          savInterval = niceBottomInterval(savMaxX.round())
                              .toDouble();
                          savBottomFormatter = (x) {
                            final i = x.round() - 1;
                            if (i < 0 || i >= savMonths.length) return '';
                            return DateFormat('MMM').format(savMonths[i]);
                          };
                          savCardTitle = 'MONTHLY BALANCE (LAST 6)';
                          break;
                        case ReportPeriod.year:
                          final savYearMonths =
                              monthStartsInYearWithTransactionsOnly(
                            year: _selectedDate.year,
                            allTransactions: transactions,
                            now: now,
                          );
                          savSpots = monthlySavingsSpotsForMonths(
                            monthStartsOldestFirst: savYearMonths,
                            newestFirst: newestFirst,
                            combinedBalanceNow: combined,
                            now: now,
                          );
                          savMinX = 1;
                          savMaxX =
                              savSpots.isEmpty ? 1 : savSpots.last.x;
                          savInterval = niceBottomInterval(savMaxX.round())
                              .toDouble();
                          savBottomFormatter = (x) {
                            final i = x.round() - 1;
                            if (i < 0 || i >= savYearMonths.length) {
                              return '';
                            }
                            return DateFormat('MMM')
                                .format(savYearMonths[i]);
                          };
                          savCardTitle =
                              'MONTHLY BALANCE (${_selectedDate.year})';
                          break;
                        case ReportPeriod.overall:
                          final savStarts = monthStartsEndingAt(
                            DateTime(now.year, now.month, 1),
                            6,
                          );
                          final savMonths =
                              monthsKeepingTransactionEntriesOnly(
                            savStarts,
                            transactions,
                          );
                          savSpots = monthlySavingsSpotsForMonths(
                            monthStartsOldestFirst: savMonths,
                            newestFirst: newestFirst,
                            combinedBalanceNow: combined,
                            now: now,
                          );
                          savMinX = 1;
                          savMaxX =
                              savSpots.isEmpty ? 1 : savSpots.last.x;
                          savInterval = niceBottomInterval(savMaxX.round())
                              .toDouble();
                          savBottomFormatter = (x) {
                            final i = x.round() - 1;
                            if (i < 0 || i >= savMonths.length) return '';
                            return DateFormat('MMM yy').format(savMonths[i]);
                          };
                          savCardTitle = 'MONTHLY BALANCE (LAST 6)';
                          break;
                      }

                      var burnTotal = 0.0;
                      var storeTotal = 0.0;
                      for (final t in transactions) {
                        final inPeriod = switch (_period) {
                          ReportPeriod.month =>
                            t.date.year == _selectedDate.year &&
                                t.date.month == _selectedDate.month,
                          ReportPeriod.year =>
                            t.date.year == _selectedDate.year,
                          ReportPeriod.overall => true,
                        };
                        if (!inPeriod) continue;
                        if (t.type == TransactionType.burn) {
                          burnTotal += t.amount;
                        } else if (t.type == TransactionType.store) {
                          storeTotal += t.amount;
                        }
                      }
                      final pieSubtitle = switch (_period) {
                        ReportPeriod.month =>
                          DateFormat('MMMM yyyy').format(_selectedDate),
                        ReportPeriod.year => '${_selectedDate.year}',
                        ReportPeriod.overall => 'All time',
                      };

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ReportPortfolioSummaryPanel(
                              accountCount: accounts.length,
                              totalBalance: displayBalance,
                              netChangeLabel: netLabel,
                              netChangeDelta: netDelta,
                              chartHeight: chartH,
                              chart: PortfolioBalanceLineChart(
                                spots: spots,
                                minX: minX,
                                maxX: maxX,
                                bottomTitleInterval: bottomInterval,
                                formatBottomTitle: bottomFormatter,
                                compareSpots: monthCompareSpots,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ReportMonthlySavingsChartCard(
                              title: savCardTitle,
                              chartHeight: savingsChartH,
                              chart: PortfolioBalanceLineChart(
                                spots: savSpots,
                                minX: savMinX,
                                maxX: savMaxX,
                                bottomTitleInterval: savInterval,
                                formatBottomTitle: savBottomFormatter,
                                lineColor: AppTheme.storeColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ReportBurnStorePieCard(
                              title: 'BURN VS STORE',
                              subtitle: pieSubtitle,
                              burnTotal: burnTotal,
                              storeTotal: storeTotal,
                            ),
                            const SizedBox(height: 12),
                            ReportCustomWidgetsSection(
                              period: _period,
                              selectedDate: _selectedDate,
                              now: now,
                              transactions: transactions,
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
