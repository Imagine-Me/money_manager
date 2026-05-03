import 'package:money_manager/domain/entities/custom_report_widget_entity.dart';

abstract class CustomReportWidgetRepository {
  Future<List<CustomReportWidgetEntity>> getAll();
  Future<void> save(CustomReportWidgetEntity entity);
  Future<void> delete(int id);
  Stream<List<CustomReportWidgetEntity>> watchAll();

  /// Persists order: first id = top of list (`sortOrder` 0, 1, …).
  Future<void> setDisplayOrder(List<int> idsInOrder);
}
