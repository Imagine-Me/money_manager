import 'package:isar/isar.dart';

part 'custom_report_widget_model.g.dart';

/// User-defined report card on the Insights tab (category tracking).
@collection
class CustomReportWidgetModel {
  Id id = Isar.autoIncrement;

  late String name;
  late List<int> categoryFilterIds;
  late bool showSubcategories;
  late DateTime createdAt;

  /// `burn` | `store` | `income` (null treated as burn for older rows).
  String? transactionType;

  /// Display order (lower = higher on screen). Reassigned when user reorders.
  int sortOrder = 0;
}
