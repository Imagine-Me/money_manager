import 'package:fl_chart/fl_chart.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/presentation/views/report/report_period_data.dart';

bool transactionMatchesTypeCategoryFilter(
  TransactionEntity t,
  TransactionType type,
  Set<int> filterIds,
  bool showSubcategories,
) {
  if (t.type != type) return false;
  if (filterIds.isEmpty) return false;
  final c = t.category;
  if (c == null) return false;
  if (showSubcategories) return filterIds.contains(c.id);
  return filterIds.contains(c.parentId ?? c.id);
}

double sumFilteredBetween(
  List<TransactionEntity> transactions,
  DateTime rangeStart,
  DateTime rangeEnd,
  TransactionType type,
  Set<int> filterIds,
  bool showSubcategories,
) {
  var s = 0.0;
  for (final t in transactions) {
    if (t.date.isBefore(rangeStart) || t.date.isAfter(rangeEnd)) continue;
    if (transactionMatchesTypeCategoryFilter(
        t, type, filterIds, showSubcategories)) {
      s += t.amount;
    }
  }
  return s;
}

/// Totals per category row for the filter sheet (sorted by amount).
Map<CategoryEntity, double> categoryAmountsForFilterSheet({
  required List<TransactionEntity> allTransactions,
  required List<CategoryEntity> allCategories,
  required ReportPeriod period,
  required DateTime selectedDate,
  required bool showSubcategories,
  required TransactionType type,
}) {
  Iterable<TransactionEntity> rows =
      allTransactions.where((t) => t.type == type);

  switch (period) {
    case ReportPeriod.month:
      final s = DateTime(selectedDate.year, selectedDate.month, 1);
      final e = DateTime(
        selectedDate.year,
        selectedDate.month + 1,
        0,
        23,
        59,
        59,
        999,
      );
      rows = rows.where((t) => !t.date.isBefore(s) && !t.date.isAfter(e));
      break;
    case ReportPeriod.year:
      final s = DateTime(selectedDate.year, 1, 1);
      final e = DateTime(selectedDate.year, 12, 31, 23, 59, 59, 999);
      rows = rows.where((t) => !t.date.isBefore(s) && !t.date.isAfter(e));
      break;
    case ReportPeriod.overall:
      break;
  }

  final sheetCats = showSubcategories
      ? allCategories
          .where((c) => c.parentId != null && c.type == type)
          .toList()
      : allCategories
          .where((c) => c.parentId == null && c.type == type)
          .toList();

  final totals = <int, double>{for (final c in sheetCats) c.id: 0.0};

  for (final t in rows) {
    final cat = t.category;
    if (cat == null) continue;
    if (showSubcategories) {
      if (cat.parentId == null) continue;
      if (!totals.containsKey(cat.id)) continue;
      totals[cat.id] = (totals[cat.id] ?? 0) + t.amount;
    } else {
      final parentId = cat.parentId ?? cat.id;
      if (!totals.containsKey(parentId)) continue;
      totals[parentId] = (totals[parentId] ?? 0) + t.amount;
    }
  }

  final entries = sheetCats
      .map((c) => MapEntry(c, totals[c.id] ?? 0.0))
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries);
}

List<FlSpot> dailyFilteredSpotsInMonth({
  required List<TransactionEntity> transactions,
  required DateTime monthAny,
  required DateTime now,
  required TransactionType type,
  required Set<int> filterIds,
  required bool showSubcategories,
}) {
  final y = monthAny.year;
  final m = monthAny.month;
  final daysInMonth = DateTime(y, m + 1, 0).day;
  final isCurrent = y == now.year && m == now.month;
  final lastDay = isCurrent ? now.day : daysInMonth;
  final spots = <FlSpot>[const FlSpot(0, 0)];
  var cumulative = 0.0;
  for (var d = 1; d <= lastDay; d++) {
    final dayStart = DateTime(y, m, d);
    final dayEnd = DateTime(y, m, d, 23, 59, 59, 999);
    var daySum = 0.0;
    for (final t in transactions) {
      if (t.date.isBefore(dayStart) || t.date.isAfter(dayEnd)) continue;
      if (transactionMatchesTypeCategoryFilter(
          t, type, filterIds, showSubcategories)) {
        daySum += t.amount;
      }
    }
    cumulative += daySum;
    spots.add(FlSpot(d.toDouble(), cumulative));
  }
  return spots;
}

List<FlSpot> monthlyFilteredSpotsInYear({
  required List<TransactionEntity> transactions,
  required int year,
  required DateTime now,
  required TransactionType type,
  required Set<int> filterIds,
  required bool showSubcategories,
}) {
  if (year > now.year) return [];
  final lastMonth = year < now.year ? 12 : now.month;
  final spots = <FlSpot>[const FlSpot(0, 0)];
  var cumulative = 0.0;
  for (var mo = 1; mo <= lastMonth; mo++) {
    final start = DateTime(year, mo, 1);
    final end = DateTime(year, mo + 1, 0, 23, 59, 59, 999);
    final v = sumFilteredBetween(
      transactions,
      start,
      end,
      type,
      filterIds,
      showSubcategories,
    );
    cumulative += v;
    spots.add(FlSpot(mo.toDouble(), cumulative));
  }
  return spots;
}

/// Last [monthCount] calendar months ending at [anchorMonthStart] (`DateTime(y,m,1)`).
/// X is 1…[monthCount] oldest→newest within the window; Y is cumulative spend through that month.
List<FlSpot> trailingMonthlyFilteredSpots({
  required List<TransactionEntity> transactions,
  required DateTime anchorMonthStart,
  required DateTime now,
  required int monthCount,
  required TransactionType type,
  required Set<int> filterIds,
  required bool showSubcategories,
}) {
  final spots = <FlSpot>[const FlSpot(0, 0)];
  var cumulative = 0.0;
  for (var k = monthCount - 1; k >= 0; k--) {
    final monthStart =
        DateTime(anchorMonthStart.year, anchorMonthStart.month - k, 1);
    final start = monthStart;
    final end = DateTime(
      monthStart.year,
      monthStart.month + 1,
      0,
      23,
      59,
      59,
      999,
    );
    final v = sumFilteredBetween(
      transactions,
      start,
      end,
      type,
      filterIds,
      showSubcategories,
    );
    cumulative += v;
    spots.add(FlSpot((monthCount - k).toDouble(), cumulative));
  }
  return spots;
}
