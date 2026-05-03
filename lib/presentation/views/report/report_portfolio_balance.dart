import 'package:fl_chart/fl_chart.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';

/// Effect of a transaction on **sum of all account balances** (transfer net = 0).
double portfolioTotalDelta(TransactionEntity t) {
  switch (t.type) {
    case TransactionType.transfer:
      return 0;
    case TransactionType.income:
      return t.accountId != null ? t.amount : 0;
    case TransactionType.burn:
    case TransactionType.store:
      return t.accountId != null ? -t.amount : 0;
  }
}

DateTime endOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

DateTime endOfMonth(DateTime anyInMonth) {
  final last = DateTime(anyInMonth.year, anyInMonth.month + 1, 0);
  return DateTime(last.year, last.month, last.day, 23, 59, 59, 999);
}

/// Last instant of the calendar month **before** [anyInMonth]'s month.
DateTime endOfPreviousMonth(DateTime anyInMonth) {
  final last = DateTime(anyInMonth.year, anyInMonth.month, 0);
  return endOfDay(last);
}

/// Combined balance after undoing every transaction strictly after [cutoffEnd].
/// [newestFirst] must be sorted newest → oldest.
double balanceAtCutoff({
  required List<TransactionEntity> newestFirst,
  required DateTime cutoffEnd,
  required double combinedBalanceNow,
}) {
  var b = combinedBalanceNow;
  for (final t in newestFirst) {
    if (!t.date.isAfter(cutoffEnd)) break;
    b -= portfolioTotalDelta(t);
  }
  return b;
}

/// Daily end-of-day balances for [month], **through today only** when [month]
/// is the current calendar month (no line into future days). Past months
/// include every day in that month.
List<FlSpot> monthlyBalanceSpots({
  required List<TransactionEntity> newestFirst,
  required DateTime month,
  required double combinedBalanceNow,
  required DateTime now,
}) {
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final isCurrentMonth =
      month.year == now.year && month.month == now.month;
  final lastDay = isCurrentMonth ? now.day : daysInMonth;

  final spots = <FlSpot>[];
  for (var day = 1; day <= lastDay; day++) {
    final cut = endOfDay(DateTime(month.year, month.month, day));
    final y = balanceAtCutoff(
      newestFirst: newestFirst,
      cutoffEnd: cut,
      combinedBalanceNow: combinedBalanceNow,
    );
    spots.add(FlSpot(day.toDouble(), y));
  }
  return spots;
}

/// Number of days in the calendar month containing [anyDayInMonth].
int daysInSelectedMonth(DateTime anyDayInMonth) =>
    DateTime(anyDayInMonth.year, anyDayInMonth.month + 1, 0).day;

/// End of the selected calendar month, or [endOfDay(now)] if that month is current.
DateTime endOfSelectedMonthCutoff(DateTime anyInMonth, DateTime now) {
  if (anyInMonth.year == now.year && anyInMonth.month == now.month) {
    return endOfDay(now);
  }
  return endOfMonth(anyInMonth);
}

/// Reconstructed combined balance at end of [selectedMonth] (any day in that month).
double balanceAtEndOfSelectedMonth({
  required List<TransactionEntity> newestFirst,
  required DateTime selectedMonth,
  required double combinedBalanceNow,
  required DateTime now,
}) {
  final cut = endOfSelectedMonthCutoff(selectedMonth, now);
  return balanceAtCutoff(
    newestFirst: newestFirst,
    cutoffEnd: cut,
    combinedBalanceNow: combinedBalanceNow,
  );
}

/// Portfolio net change during the selected calendar month.
double netChangeInSelectedMonth({
  required List<TransactionEntity> newestFirst,
  required DateTime selectedMonth,
  required double combinedBalanceNow,
  required DateTime now,
}) {
  final anchor = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final atEnd = balanceAtEndOfSelectedMonth(
    newestFirst: newestFirst,
    selectedMonth: selectedMonth,
    combinedBalanceNow: combinedBalanceNow,
    now: now,
  );
  final atStart = balanceAtCutoff(
    newestFirst: newestFirst,
    cutoffEnd: endOfPreviousMonth(anchor),
    combinedBalanceNow: combinedBalanceNow,
  );
  return atEnd - atStart;
}

/// End of selected [year] for balance snapshot (31 Dec past years, else through today).
DateTime endOfSelectedYearCutoff(int year, DateTime now) {
  if (year >= now.year) return endOfDay(now);
  return endOfMonth(DateTime(year, 12, 1));
}

double balanceAtEndOfSelectedYear({
  required List<TransactionEntity> newestFirst,
  required int year,
  required double combinedBalanceNow,
  required DateTime now,
}) {
  return balanceAtCutoff(
    newestFirst: newestFirst,
    cutoffEnd: endOfSelectedYearCutoff(year, now),
    combinedBalanceNow: combinedBalanceNow,
  );
}

/// Net change from end of Dec (year − 1) through end of [year] (or today if current year).
double netChangeInSelectedYear({
  required List<TransactionEntity> newestFirst,
  required int year,
  required double combinedBalanceNow,
  required DateTime now,
}) {
  final atEnd = balanceAtEndOfSelectedYear(
    newestFirst: newestFirst,
    year: year,
    combinedBalanceNow: combinedBalanceNow,
    now: now,
  );
  final atStart = balanceAtCutoff(
    newestFirst: newestFirst,
    cutoffEnd: endOfMonth(DateTime(year - 1, 12, 1)),
    combinedBalanceNow: combinedBalanceNow,
  );
  return atEnd - atStart;
}

/// [count] first-of-month dates, oldest → newest, ending at [endYm] (`DateTime(y, m, 1)`).
List<DateTime> monthStartsEndingAt(DateTime endYm, int count) {
  return List.generate(
    count,
    (k) => DateTime(endYm.year, endYm.month - (count - 1 - k), 1),
  );
}

/// True if [monthStart] (`DateTime(y, m, 1)`) has at least one transaction in that month.
bool monthHasAnyTransaction(
  DateTime monthStart,
  List<TransactionEntity> allTransactions,
) {
  final y = monthStart.year;
  final m = monthStart.month;
  for (final t in allTransactions) {
    if (t.date.year == y && t.date.month == m) return true;
  }
  return false;
}

/// Keeps only month starts where [monthHasAnyTransaction] is true (order preserved).
List<DateTime> monthsKeepingTransactionEntriesOnly(
  Iterable<DateTime> candidateMonthStarts,
  List<TransactionEntity> allTransactions,
) {
  return candidateMonthStarts
      .where((d) => monthHasAnyTransaction(d, allTransactions))
      .toList();
}

/// Last six calendar months ending at [selectedMonthAny], with **no** months that have zero transactions.
List<DateTime> filteredLastSixTransactionMonths({
  required List<TransactionEntity> allTransactions,
  required DateTime selectedMonthAny,
}) {
  final end = DateTime(selectedMonthAny.year, selectedMonthAny.month, 1);
  return monthsKeepingTransactionEntriesOnly(
    monthStartsEndingAt(end, 6),
    allTransactions,
  );
}

/// Month starts Jan…[last month in year] that have at least one transaction.
List<DateTime> monthStartsInYearWithTransactionsOnly({
  required int year,
  required List<TransactionEntity> allTransactions,
  required DateTime now,
}) {
  if (year > now.year) return [];
  final lastM = year == now.year ? now.month : 12;
  return monthsKeepingTransactionEntriesOnly(
    [for (var m = 1; m <= lastM; m++) DateTime(year, m, 1)],
    allTransactions,
  );
}

/// Combined portfolio balance at **end of each month** (x = 1 … n).
/// Past months use last moment of that month; the **current** month uses
/// balance through today (same as total across accounts now).
List<FlSpot> monthlySavingsSpotsForMonths({
  required List<DateTime> monthStartsOldestFirst,
  required List<TransactionEntity> newestFirst,
  required double combinedBalanceNow,
  required DateTime now,
}) {
  return List.generate(monthStartsOldestFirst.length, (i) {
    final y = balanceAtEndOfSelectedMonth(
      newestFirst: newestFirst,
      selectedMonth: monthStartsOldestFirst[i],
      combinedBalanceNow: combinedBalanceNow,
      now: now,
    );
    return FlSpot((i + 1).toDouble(), y);
  });
}

/// Last six calendar months of end-of-month balance ending at
/// [selectedMonthAny]'s month, **excluding months with no transactions**.
List<FlSpot> monthlySavingsLastSixSpots({
  required List<TransactionEntity> newestFirst,
  required List<TransactionEntity> allTransactions,
  required DateTime selectedMonthAny,
  required double combinedBalanceNow,
  required DateTime now,
}) {
  final filtered = filteredLastSixTransactionMonths(
    allTransactions: allTransactions,
    selectedMonthAny: selectedMonthAny,
  );
  return monthlySavingsSpotsForMonths(
    monthStartsOldestFirst: filtered,
    newestFirst: newestFirst,
    combinedBalanceNow: combinedBalanceNow,
    now: now,
  );
}

/// Months in [year] that have at least one transaction, in calendar order;
/// y is combined balance at each month-end (today for current month); x is 1 … n.
List<FlSpot> monthlySavingsSpotsInYear({
  required List<TransactionEntity> newestFirst,
  required List<TransactionEntity> allTransactions,
  required int year,
  required double combinedBalanceNow,
  required DateTime now,
}) {
  final filtered = monthStartsInYearWithTransactionsOnly(
    year: year,
    allTransactions: allTransactions,
    now: now,
  );
  return monthlySavingsSpotsForMonths(
    monthStartsOldestFirst: filtered,
    newestFirst: newestFirst,
    combinedBalanceNow: combinedBalanceNow,
    now: now,
  );
}

/// One point per month in [year]: balance at end of each month (1–12).
List<FlSpot> yearlyBalanceSpots({
  required List<TransactionEntity> newestFirst,
  required int year,
  required double combinedBalanceNow,
  required DateTime now,
}) {
  final spots = <FlSpot>[];
  for (var m = 1; m <= 12; m++) {
    if (year > now.year) break;
    if (year == now.year && m > now.month) break;

    final cut = (year == now.year && m == now.month)
        ? endOfDay(now)
        : endOfMonth(DateTime(year, m));

    final y = balanceAtCutoff(
      newestFirst: newestFirst,
      cutoffEnd: cut,
      combinedBalanceNow: combinedBalanceNow,
    );
    spots.add(FlSpot(m.toDouble(), y));
  }
  return spots;
}

/// Last [monthCount] calendar months ending at [anchor] month (oldest → newest on x).
List<({DateTime monthStart, double y})> overallBalancePoints({
  required List<TransactionEntity> newestFirst,
  required DateTime anchor,
  required double combinedBalanceNow,
  required DateTime now,
  int monthCount = 24,
}) {
  final out = <({DateTime monthStart, double y})>[];
  for (var k = 0; k < monthCount; k++) {
    final monthStart =
        DateTime(anchor.year, anchor.month - (monthCount - 1 - k), 1);
    final DateTime cut;
    if (monthStart.year == now.year && monthStart.month == now.month) {
      cut = endOfDay(now);
    } else {
      cut = endOfMonth(monthStart);
    }
    final y = balanceAtCutoff(
      newestFirst: newestFirst,
      cutoffEnd: cut,
      combinedBalanceNow: combinedBalanceNow,
    );
    out.add((monthStart: monthStart, y: y));
  }
  return out;
}

double niceBottomInterval(int maxX) {
  if (maxX <= 7) return 1;
  if (maxX <= 14) return 2;
  if (maxX <= 21) return 3;
  return 5;
}

