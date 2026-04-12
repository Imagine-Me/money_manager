import 'package:intl/intl.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';

enum ReportPeriod { month, year, overall }

enum ReportTypeTab { burn, store, income }

// ─── Helpers ──────────────────────────────────────────────────────────────────

String periodToStr(ReportPeriod p) => switch (p) {
      ReportPeriod.month => 'month',
      ReportPeriod.year => 'year',
      ReportPeriod.overall => 'overall',
    };

String typeTabToStr(ReportTypeTab t) => switch (t) {
      ReportTypeTab.burn => 'burn',
      ReportTypeTab.store => 'store',
      ReportTypeTab.income => 'income',
    };

ReportPeriod periodFromStr(String s) => switch (s) {
      'year' => ReportPeriod.year,
      'overall' => ReportPeriod.overall,
      _ => ReportPeriod.month,
    };

ReportTypeTab typeTabFromStr(String s) => switch (s) {
      'store' => ReportTypeTab.store,
      'income' => ReportTypeTab.income,
      _ => ReportTypeTab.burn,
    };

// ─── Period data computation ──────────────────────────────────────────────────

class PeriodData {
  final double totalBurn;
  final double totalStore;
  final double totalIncome;
  final int burnCount;
  final int storeCount;
  final int incomeCount;
  final Map<CategoryEntity, double> burnBreakdown;
  final Map<CategoryEntity, double> storeBreakdown;
  final Map<CategoryEntity, double> incomeBreakdown;
  final Map<CategoryEntity, double> burnParentBreakdown;
  final Map<CategoryEntity, double> storeParentBreakdown;
  final Map<CategoryEntity, double> incomeParentBreakdown;
  final List<TransactionEntity> transactions;
  final List<String> barLabels;
  final List<double> barValues;
  final String periodLabel;

  const PeriodData({
    required this.totalBurn,
    required this.totalStore,
    required this.totalIncome,
    required this.burnCount,
    required this.storeCount,
    required this.incomeCount,
    required this.burnBreakdown,
    required this.storeBreakdown,
    required this.incomeBreakdown,
    required this.burnParentBreakdown,
    required this.storeParentBreakdown,
    required this.incomeParentBreakdown,
    required this.transactions,
    required this.barLabels,
    required this.barValues,
    required this.periodLabel,
  });

  factory PeriodData.compute(
    List<TransactionEntity> all,
    List<CategoryEntity> allCategories,
    ReportPeriod period,
    DateTime selectedDate, {
    TransactionType? typeFilter,
    Set<int> categoryIdFilter = const {},
    bool showSubcategories = false,
  }) {
    final now = selectedDate;
    List<TransactionEntity> filtered;
    List<String> labels;
    List<double> values = [];
    String periodLabel;
    int? daysInMonth;

    switch (period) {
      case ReportPeriod.month:
        daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        filtered = all
            .where(
                (t) => t.date.year == now.year && t.date.month == now.month)
            .toList();
        labels = List.generate(daysInMonth, (i) => '${i + 1}');
        periodLabel = DateFormat('MMMM yyyy').format(now);
        break;

      case ReportPeriod.year:
        filtered = all.where((t) => t.date.year == now.year).toList();
        labels = List.generate(
            12, (i) => DateFormat('MMM').format(DateTime(now.year, i + 1)));
        periodLabel = now.year.toString();
        break;

      case ReportPeriod.overall:
        filtered = all.toList();
        labels = [];
        periodLabel = 'All Time';
        break;
    }

    if (typeFilter != null) {
      filtered = filtered.where((t) => t.type == typeFilter).toList();
    }

    if (categoryIdFilter.isNotEmpty) {
      filtered = filtered.where((t) {
        if (t.category == null) return false;
        final cat = t.category!;
        if (showSubcategories) return categoryIdFilter.contains(cat.id);
        return categoryIdFilter.contains(cat.parentId ?? cat.id);
      }).toList();
    }

    filtered.sort((a, b) => b.date.compareTo(a.date));

    switch (period) {
      case ReportPeriod.month:
        values = List.generate(
            daysInMonth!,
            (i) => filtered
                .where((t) => t.date.day == i + 1)
                .fold(0.0, (s, t) => s + t.amount));
        break;
      case ReportPeriod.year:
        values = List.generate(
            12,
            (m) => filtered
                .where((t) => t.date.month == m + 1)
                .fold(0.0, (s, t) => s + t.amount));
        break;
      case ReportPeriod.overall:
        break;
    }

    final totalBurn = filtered
        .where((t) => t.type == TransactionType.burn)
        .fold(0.0, (s, t) => s + t.amount);
    final totalStore = filtered
        .where((t) => t.type == TransactionType.store)
        .fold(0.0, (s, t) => s + t.amount);
    final totalIncome = filtered
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);

    final burnBreakdown = _breakdown(filtered, TransactionType.burn);
    final storeBreakdown = _breakdown(filtered, TransactionType.store);
    final incomeBreakdown = _breakdown(filtered, TransactionType.income);

    return PeriodData(
      totalBurn: totalBurn,
      totalStore: totalStore,
      totalIncome: totalIncome,
      burnCount: filtered.where((t) => t.type == TransactionType.burn).length,
      storeCount:
          filtered.where((t) => t.type == TransactionType.store).length,
      incomeCount:
          filtered.where((t) => t.type == TransactionType.income).length,
      burnBreakdown: burnBreakdown,
      storeBreakdown: storeBreakdown,
      incomeBreakdown: incomeBreakdown,
      burnParentBreakdown: _parentBreakdown(burnBreakdown, allCategories),
      storeParentBreakdown: _parentBreakdown(storeBreakdown, allCategories),
      incomeParentBreakdown: _parentBreakdown(incomeBreakdown, allCategories),
      transactions: filtered,
      barLabels: labels,
      barValues: values,
      periodLabel: periodLabel,
    );
  }

  double totalFor(TransactionType type) => switch (type) {
        TransactionType.burn => totalBurn,
        TransactionType.store => totalStore,
        TransactionType.income => totalIncome,
        _ => 0,
      };

  int countFor(TransactionType type) => switch (type) {
        TransactionType.burn => burnCount,
        TransactionType.store => storeCount,
        TransactionType.income => incomeCount,
        _ => 0,
      };

  Map<CategoryEntity, double> breakdownFor(TransactionType type) =>
      switch (type) {
        TransactionType.burn => burnBreakdown,
        TransactionType.store => storeBreakdown,
        TransactionType.income => incomeBreakdown,
        _ => {},
      };

  Map<CategoryEntity, double> parentBreakdownFor(TransactionType type) =>
      switch (type) {
        TransactionType.burn => burnParentBreakdown,
        TransactionType.store => storeParentBreakdown,
        TransactionType.income => incomeParentBreakdown,
        _ => {},
      };

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
