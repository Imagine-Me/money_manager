import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/domain/entities/account_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/presentation/views/report/report_period_data.dart';
import 'package:money_manager/presentation/views/report/report_portfolio_balance.dart';

/// Portfolio chart, savings chart, and burn/store totals for the Insights list
/// (and detail hero), for one period + selected date.
class ReportInsightsListDerivedData {
  const ReportInsightsListDerivedData({
    required this.accountCount,
    required this.combinedBalance,
    required this.portfolioSpots,
    required this.portfolioMinX,
    required this.portfolioMaxX,
    required this.portfolioBottomInterval,
    required this.portfolioBottomFormatter,
    required this.monthCompareSpots,
    required this.displayBalance,
    required this.netDelta,
    required this.netLabel,
    required this.savSpots,
    required this.savMinX,
    required this.savMaxX,
    required this.savInterval,
    required this.savBottomFormatter,
    required this.savCardTitle,
    required this.burnTotal,
    required this.storeTotal,
    required this.pieSubtitle,
  });

  final int accountCount;
  final double combinedBalance;

  final List<FlSpot> portfolioSpots;
  final double portfolioMinX;
  final double portfolioMaxX;
  final double portfolioBottomInterval;
  final String Function(double x)? portfolioBottomFormatter;
  final List<FlSpot>? monthCompareSpots;

  final double displayBalance;
  final double netDelta;
  final String netLabel;

  final List<FlSpot> savSpots;
  final double savMinX;
  final double savMaxX;
  final double savInterval;
  final String Function(double x)? savBottomFormatter;
  final String savCardTitle;

  final double burnTotal;
  final double storeTotal;
  final String pieSubtitle;

  factory ReportInsightsListDerivedData.compute({
    required List<TransactionEntity> transactions,
    required List<AccountEntity> accounts,
    required ReportPeriod period,
    required DateTime selectedDate,
    required DateTime now,
  }) {
    final combined =
        accounts.fold(0.0, (double s, AccountEntity a) => s + a.balance);
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

    switch (period) {
      case ReportPeriod.month:
        final daysInMonth = daysInSelectedMonth(selectedDate);
        spots = monthlyBalanceSpots(
          newestFirst: newestFirst,
          month: selectedDate,
          combinedBalanceNow: combined,
          now: now,
        );
        final prevMonthStart =
            DateTime(selectedDate.year, selectedDate.month - 1, 1);
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
        bottomInterval = niceBottomInterval(maxX.round()).toDouble();
        bottomFormatter = null;

        displayBalance = balanceAtEndOfSelectedMonth(
          newestFirst: newestFirst,
          selectedMonth: selectedDate,
          combinedBalanceNow: combined,
          now: now,
        );
        netDelta = netChangeInSelectedMonth(
          newestFirst: newestFirst,
          selectedMonth: selectedDate,
          combinedBalanceNow: combined,
          now: now,
        );
        final isSelCurrent =
            selectedDate.year == now.year && selectedDate.month == now.month;
        netLabel = isSelCurrent
            ? 'Saved this month'
            : 'Net in ${DateFormat('MMMM yyyy').format(selectedDate)}';
        break;
      case ReportPeriod.year:
        monthCompareSpots = null;
        spots = yearlyBalanceSpots(
          newestFirst: newestFirst,
          year: selectedDate.year,
          combinedBalanceNow: combined,
          now: now,
        );
        minX = 1;
        maxX = spots.isEmpty ? 1 : spots.last.x;
        bottomInterval = 1;
        bottomFormatter = (double x) => DateFormat('MMM')
            .format(DateTime(selectedDate.year, x.round(), 1));

        displayBalance = balanceAtEndOfSelectedYear(
          newestFirst: newestFirst,
          year: selectedDate.year,
          combinedBalanceNow: combined,
          now: now,
        );
        netDelta = netChangeInSelectedYear(
          newestFirst: newestFirst,
          year: selectedDate.year,
          combinedBalanceNow: combined,
          now: now,
        );
        netLabel = 'Net in ${selectedDate.year}';
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
        bottomFormatter = (double x) {
          final i = x.round() - 1;
          if (i < 0 || i >= points.length) return '';
          return DateFormat('MMM yy').format(points[i].monthStart);
        };

        displayBalance = combined;
        netDelta =
            points.length >= 2 ? points.last.y - points.first.y : 0;
        netLabel = 'Net (24 months)';
        break;
    }

    var savSpots = <FlSpot>[];
    var savMinX = 1.0;
    var savMaxX = 6.0;
    var savInterval = 1.0;
    String Function(double x)? savBottomFormatter;
    var savCardTitle = 'MONTHLY BALANCE';

    switch (period) {
      case ReportPeriod.month:
        final savMonths = filteredLastSixTransactionMonths(
          allTransactions: transactions,
          selectedMonthAny: selectedDate,
        );
        savSpots = monthlySavingsSpotsForMonths(
          monthStartsOldestFirst: savMonths,
          newestFirst: newestFirst,
          combinedBalanceNow: combined,
          now: now,
        );
        savMinX = 1;
        savMaxX = savSpots.isEmpty ? 1 : savSpots.last.x;
        savInterval = niceBottomInterval(savMaxX.round()).toDouble();
        savBottomFormatter = (double x) {
          final i = x.round() - 1;
          if (i < 0 || i >= savMonths.length) return '';
          return DateFormat('MMM').format(savMonths[i]);
        };
        savCardTitle = 'MONTHLY BALANCE (LAST 6)';
        break;
      case ReportPeriod.year:
        final savYearMonths = monthStartsInYearWithTransactionsOnly(
          year: selectedDate.year,
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
        savMaxX = savSpots.isEmpty ? 1 : savSpots.last.x;
        savInterval = niceBottomInterval(savMaxX.round()).toDouble();
        savBottomFormatter = (double x) {
          final i = x.round() - 1;
          if (i < 0 || i >= savYearMonths.length) {
            return '';
          }
          return DateFormat('MMM').format(savYearMonths[i]);
        };
        savCardTitle = 'MONTHLY BALANCE (${selectedDate.year})';
        break;
      case ReportPeriod.overall:
        final savStarts = monthStartsEndingAt(
          DateTime(now.year, now.month, 1),
          6,
        );
        final savMonths = monthsKeepingTransactionEntriesOnly(
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
        savMaxX = savSpots.isEmpty ? 1 : savSpots.last.x;
        savInterval = niceBottomInterval(savMaxX.round()).toDouble();
        savBottomFormatter = (double x) {
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
      final inPeriod = switch (period) {
        ReportPeriod.month =>
          t.date.year == selectedDate.year &&
              t.date.month == selectedDate.month,
        ReportPeriod.year => t.date.year == selectedDate.year,
        ReportPeriod.overall => true,
      };
      if (!inPeriod) continue;
      if (t.type == TransactionType.burn) {
        burnTotal += t.amount;
      } else if (t.type == TransactionType.store) {
        storeTotal += t.amount;
      }
    }

    final pieSubtitle = switch (period) {
      ReportPeriod.month =>
        DateFormat('MMMM yyyy').format(selectedDate),
      ReportPeriod.year => '${selectedDate.year}',
      ReportPeriod.overall => 'All time',
    };

    return ReportInsightsListDerivedData(
      accountCount: accounts.length,
      combinedBalance: combined,
      portfolioSpots: spots,
      portfolioMinX: minX,
      portfolioMaxX: maxX,
      portfolioBottomInterval: bottomInterval,
      portfolioBottomFormatter: bottomFormatter,
      monthCompareSpots: monthCompareSpots,
      displayBalance: displayBalance,
      netDelta: netDelta,
      netLabel: netLabel,
      savSpots: savSpots,
      savMinX: savMinX,
      savMaxX: savMaxX,
      savInterval: savInterval,
      savBottomFormatter: savBottomFormatter,
      savCardTitle: savCardTitle,
      burnTotal: burnTotal,
      storeTotal: storeTotal,
      pieSubtitle: pieSubtitle,
    );
  }
}
