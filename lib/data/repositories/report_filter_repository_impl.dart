import 'package:isar/isar.dart';
import 'package:money_manager/data/datasources/local/isar_service.dart';
import 'package:money_manager/data/models/report_filter_model.dart';
import 'package:money_manager/domain/entities/report_filter_entity.dart';
import 'package:money_manager/domain/repositories/report_filter_repository.dart';

class ReportFilterRepositoryImpl implements ReportFilterRepository {
  ReportFilterRepositoryImpl(this._service);

  final IsarService _service;

  Isar get _db => _service.db;

  ReportFilterEntity _toEntity(ReportFilterModel m) => ReportFilterEntity(
        id: m.id,
        name: m.name,
        period: m.period,
        typeTab: m.typeTab,
        categoryFilterIds: List<int>.from(m.categoryFilterIds),
        showSubcategories: m.showSubcategories,
        createdAt: m.createdAt,
      );

  ReportFilterModel _toModel(ReportFilterEntity e) {
    final m = ReportFilterModel()
      ..name = e.name
      ..period = e.period
      ..typeTab = e.typeTab
      ..categoryFilterIds = e.categoryFilterIds
      ..showSubcategories = e.showSubcategories
      ..createdAt = e.createdAt;
    if (e.id != 0) m.id = e.id;
    return m;
  }

  @override
  Future<List<ReportFilterEntity>> getAll() async {
    final models = await _db.reportFilterModels.where().findAll();
    return models.map(_toEntity).toList();
  }

  @override
  Future<void> save(ReportFilterEntity filter) async {
    await _db.writeTxn(() async {
      await _db.reportFilterModels.put(_toModel(filter));
    });
  }

  @override
  Future<void> delete(int id) async {
    await _db.writeTxn(() async {
      await _db.reportFilterModels.delete(id);
    });
  }

  @override
  Stream<List<ReportFilterEntity>> watchAll() {
    return _db.reportFilterModels
        .where()
        .watch(fireImmediately: true)
        .map((list) => list.map(_toEntity).toList());
  }
}
