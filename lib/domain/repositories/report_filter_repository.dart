import 'package:money_manager/domain/entities/report_filter_entity.dart';

abstract class ReportFilterRepository {
  Future<List<ReportFilterEntity>> getAll();
  Future<void> save(ReportFilterEntity filter);
  Future<void> delete(int id);
  Stream<List<ReportFilterEntity>> watchAll();
}
