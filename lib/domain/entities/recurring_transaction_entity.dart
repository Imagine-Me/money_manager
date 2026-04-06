import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/domain/entities/category_entity.dart';

class RecurringTransactionEntity {
  final int id;
  final String title;
  final double amount;
  final TransactionType type; // only burn or store
  final String note;
  final RecurringFrequency frequency;

  /// ISO weekday (1=Mon…7=Sun) for weekly;
  /// day of month (1–31) for monthly/yearly.
  final int recurDay;

  /// Month (1–12), only used when frequency == yearly.
  final int recurMonth;

  final int? accountId;
  final DateTime? lastExecutedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final CategoryEntity? category;

  const RecurringTransactionEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.note,
    required this.frequency,
    required this.recurDay,
    this.recurMonth = 1,
    this.accountId,
    this.lastExecutedDate,
    this.startDate,
    this.endDate,
    this.category,
  });

  /// Returns true if this recurring transaction is due today and hasn't been
  /// executed yet for the current period.
  bool isDueToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Not yet started.
    if (startDate != null) {
      final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
      if (today.isBefore(start)) return false;
    }

    // Already expired.
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (today.isAfter(end)) return false;
    }

    if (lastExecutedDate != null) {
      final last = DateTime(
        lastExecutedDate!.year,
        lastExecutedDate!.month,
        lastExecutedDate!.day,
      );
      // Already executed today — skip.
      if (!last.isBefore(today)) return false;
    }

    return switch (frequency) {
      RecurringFrequency.weekly => now.weekday == recurDay,
      RecurringFrequency.monthly => now.day == recurDay,
      RecurringFrequency.yearly =>
        now.day == recurDay && now.month == recurMonth,
    };
  }
}
