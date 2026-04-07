class ReportFilterEntity {
  final int id;
  final String name;

  /// 'month' | 'year' | 'overall'
  final String period;

  /// 'burn' | 'store'
  final String typeTab;

  final List<int> categoryFilterIds;
  final bool showSubcategories;
  final DateTime createdAt;

  const ReportFilterEntity({
    required this.id,
    required this.name,
    required this.period,
    required this.typeTab,
    required this.categoryFilterIds,
    required this.showSubcategories,
    required this.createdAt,
  });
}
