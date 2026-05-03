import 'package:money_manager/core/constants/app_constants.dart';

class CustomReportWidgetEntity {
  const CustomReportWidgetEntity({
    required this.id,
    required this.name,
    required this.categoryFilterIds,
    required this.showSubcategories,
    required this.createdAt,
    required this.typeFilter,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final List<int> categoryFilterIds;
  final bool showSubcategories;
  final DateTime createdAt;

  /// Which transaction type this report tracks.
  final TransactionType typeFilter;

  /// Lower values appear first; reassigned on reorder.
  final int sortOrder;

  static TransactionType typeFilterFromStored(String? raw) {
    return switch (raw) {
      'store' => TransactionType.store,
      'income' => TransactionType.income,
      _ => TransactionType.burn,
    };
  }

  static String typeFilterToStored(TransactionType t) {
    return switch (t) {
      TransactionType.store => 'store',
      TransactionType.income => 'income',
      _ => 'burn',
    };
  }
}
