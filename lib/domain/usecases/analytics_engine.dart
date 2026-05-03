import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';

class AnalyticsEngine {
  const AnalyticsEngine();

  /// Delta %: (current week spend - previous week spend) / previous week spend * 100
  double calculateDelta(List<TransactionEntity> transactions) {
    final now = DateTime.now();
    final currentWeekStart = _startOfWeek(now);
    final lastWeekStart = currentWeekStart.subtract(const Duration(days: 7));

    final currentTotal = _sumBurn(
      transactions.where((t) =>
          t.type == TransactionType.burn &&
          !t.date.isBefore(currentWeekStart) && !t.date.isAfter(now)),
    );

    final lastTotal = _sumBurn(
      transactions.where((t) =>
          t.type == TransactionType.burn &&
          !t.date.isBefore(lastWeekStart) &&
          t.date.isBefore(currentWeekStart)),
    );

    if (lastTotal == 0) return 0;
    return ((currentTotal - lastTotal) / lastTotal) * 100;
  }

  /// Category breakdown for pie chart — burn transactions only.
  Map<CategoryEntity, double> getCategoryBreakdown(
    List<TransactionEntity> transactions, {
    TransactionType type = TransactionType.burn,
  }) {
    final Map<CategoryEntity, double> breakdown = {};
    for (final t in transactions) {
      if (t.type != type) continue;
      if (t.category == null) continue;
      breakdown[t.category!] = (breakdown[t.category!] ?? 0) + t.amount;
    }
    return Map.fromEntries(
      breakdown.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Parent-level rollup: subcategories are grouped under their parent.
  /// Categories with no parent are grouped by themselves.
  Map<CategoryEntity, double> getParentCategoryBreakdown(
    List<TransactionEntity> transactions, {
    required List<CategoryEntity> allCategories,
    TransactionType type = TransactionType.burn,
  }) {
    final parentMap = {for (final c in allCategories) c.id: c};
    final Map<CategoryEntity, double> breakdown = {};
    for (final t in transactions) {
      if (t.type != type || t.category == null) continue;
      final cat = t.category!;
      final effectiveCat = cat.parentId != null && parentMap.containsKey(cat.parentId!)
          ? parentMap[cat.parentId!]!
          : cat;
      breakdown[effectiveCat] = (breakdown[effectiveCat] ?? 0) + t.amount;
    }
    return Map.fromEntries(
      breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Weekly spending for the past 7 days — burn only.
  List<double> getWeeklySpend(List<TransactionEntity> transactions) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day - (6 - i));
      return _sumBurn(
        transactions.where((t) =>
            t.type == TransactionType.burn &&
            t.date.year == day.year &&
            t.date.month == day.month &&
            t.date.day == day.day),
      );
    });
  }

  double getTotalBurn(List<TransactionEntity> transactions) =>
      _sumBurn(transactions.where((t) => t.type == TransactionType.burn));

  double getTotalStore(List<TransactionEntity> transactions) =>
      _sumBurn(transactions.where((t) => t.type == TransactionType.store));

  double getMonthlyBurn(List<TransactionEntity> transactions) {
    final now = DateTime.now();
    return _sumBurn(transactions.where(
      (t) =>
          t.type == TransactionType.burn &&
          t.date.year == now.year &&
          t.date.month == now.month,
    ));
  }

  double getMonthlyStore(List<TransactionEntity> transactions) {
    final now = DateTime.now();
    return _sumBurn(transactions.where(
      (t) =>
          t.type == TransactionType.store &&
          t.date.year == now.year &&
          t.date.month == now.month,
    ));
  }

  double getPrevMonthlyBurn(List<TransactionEntity> transactions) {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1);
    return _sumBurn(transactions.where(
      (t) =>
          t.type == TransactionType.burn &&
          t.date.year == prev.year &&
          t.date.month == prev.month,
    ));
  }

  double getPrevMonthlyStore(List<TransactionEntity> transactions) {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1);
    return _sumBurn(transactions.where(
      (t) =>
          t.type == TransactionType.store &&
          t.date.year == prev.year &&
          t.date.month == prev.month,
    ));
  }

  /// All transactions for the current calendar month.
  List<TransactionEntity> getMonthlyTransactions(
      List<TransactionEntity> transactions) {
    final now = DateTime.now();
    return transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
  }

  double _sumBurn(Iterable<TransactionEntity> transactions) =>
      transactions.fold(0.0, (sum, t) => sum + t.amount);

  DateTime _startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Per–calendar-day burn for the previous month vs the current month.
  /// The month-vs-month chart sums these into cumulative (running) totals.
  MonthOverMonthDailySpend getMonthOverMonthDailyBurn(
    List<TransactionEntity> transactions,
  ) {
    final now = DateTime.now();
    final cy = now.year;
    final cm = now.month;
    final cd = now.day;

    final prev = DateTime(cy, cm - 1);
    final py = prev.year;
    final pm = prev.month;
    final daysPrev = DateTime(py, pm + 1, 0).day;
    final daysCurr = DateTime(cy, cm + 1, 0).day;

    final prevDaily = List<double>.filled(daysPrev, 0);
    final currDaily = List<double>.filled(daysCurr, 0);

    for (final t in transactions) {
      if (t.type != TransactionType.burn) continue;
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      if (d.year == py && d.month == pm) {
        prevDaily[d.day - 1] += t.amount;
      } else if (d.year == cy && d.month == cm) {
        currDaily[d.day - 1] += t.amount;
      }
    }

    return MonthOverMonthDailySpend(
      previousYear: py,
      previousMonth: pm,
      previousMonthDaily: prevDaily,
      currentYear: cy,
      currentMonth: cm,
      currentMonthDaily: currDaily,
      todayDay: cd.clamp(1, daysCurr),
    );
  }
}

/// Daily burn per calendar day (index 0 = day 1). Cumulative series is derived in UI.
class MonthOverMonthDailySpend {
  const MonthOverMonthDailySpend({
    required this.previousYear,
    required this.previousMonth,
    required this.previousMonthDaily,
    required this.currentYear,
    required this.currentMonth,
    required this.currentMonthDaily,
    required this.todayDay,
  });

  final int previousYear;
  final int previousMonth;
  final List<double> previousMonthDaily;
  final int currentYear;
  final int currentMonth;
  final List<double> currentMonthDaily;
  /// Current calendar day (1-based), clamped to this month’s length.
  final int todayDay;
}
