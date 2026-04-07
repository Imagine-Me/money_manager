import 'package:isar/isar.dart';

part 'report_filter_model.g.dart';

@collection
class ReportFilterModel {
  Id id = Isar.autoIncrement;

  late String name;

  /// 'month' | 'year' | 'overall'
  late String period;

  /// 'burn' | 'store'
  late String typeTab;

  late List<int> categoryFilterIds;
  late bool showSubcategories;
  late DateTime createdAt;
}
