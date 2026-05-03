import 'dart:math' as math;

import 'package:isar/isar.dart';
import 'package:money_manager/data/datasources/local/isar_service.dart';
import 'package:money_manager/data/models/custom_report_widget_model.dart';
import 'package:money_manager/domain/entities/custom_report_widget_entity.dart';
import 'package:money_manager/domain/repositories/custom_report_widget_repository.dart';
import 'package:money_manager/services/backup_service.dart';

class CustomReportWidgetRepositoryImpl implements CustomReportWidgetRepository {
  CustomReportWidgetRepositoryImpl(this._service);

  final IsarService _service;

  Isar get _db => _service.db;

  CustomReportWidgetEntity _toEntity(CustomReportWidgetModel m) =>
      CustomReportWidgetEntity(
        id: m.id,
        name: m.name,
        categoryFilterIds: List<int>.from(m.categoryFilterIds),
        showSubcategories: m.showSubcategories,
        createdAt: m.createdAt,
        typeFilter: CustomReportWidgetEntity.typeFilterFromStored(
          m.transactionType,
        ),
        sortOrder: m.sortOrder,
      );

  CustomReportWidgetModel _toModel(CustomReportWidgetEntity e) {
    final m = CustomReportWidgetModel()
      ..name = e.name
      ..categoryFilterIds = e.categoryFilterIds
      ..showSubcategories = e.showSubcategories
      ..createdAt = e.createdAt
      ..transactionType = CustomReportWidgetEntity.typeFilterToStored(
        e.typeFilter,
      )
      ..sortOrder = e.sortOrder;
    if (e.id != 0) m.id = e.id;
    return m;
  }

  List<CustomReportWidgetEntity> _sortedEntities(
    List<CustomReportWidgetModel> models,
  ) {
    final sorted = [...models]
      ..sort((a, b) {
        final o = a.sortOrder.compareTo(b.sortOrder);
        if (o != 0) return o;
        return b.createdAt.compareTo(a.createdAt);
      });
    return sorted.map(_toEntity).toList();
  }

  Future<int> _nextSortOrder() async {
    final all = await _db.customReportWidgetModels.where().findAll();
    if (all.isEmpty) return 0;
    return all.map((m) => m.sortOrder).reduce(math.max) + 1;
  }

  @override
  Future<List<CustomReportWidgetEntity>> getAll() async {
    final models = await _db.customReportWidgetModels.where().findAll();
    return _sortedEntities(models);
  }

  @override
  Future<void> save(CustomReportWidgetEntity entity) async {
    var toSave = entity;
    if (entity.id == 0) {
      final next = await _nextSortOrder();
      toSave = CustomReportWidgetEntity(
        id: 0,
        name: entity.name,
        categoryFilterIds: entity.categoryFilterIds,
        showSubcategories: entity.showSubcategories,
        createdAt: entity.createdAt,
        typeFilter: entity.typeFilter,
        sortOrder: next,
      );
    }
    await _db.writeTxn(() async {
      await _db.customReportWidgetModels.put(_toModel(toSave));
    });
    BackupService.instance.triggerAutoSync();
  }

  @override
  Future<void> delete(int id) async {
    await _db.writeTxn(() async {
      await _db.customReportWidgetModels.delete(id);
    });
    BackupService.instance.triggerAutoSync();
  }

  @override
  Stream<List<CustomReportWidgetEntity>> watchAll() {
    return _db.customReportWidgetModels
        .where()
        .watch(fireImmediately: true)
        .map(_sortedEntities);
  }

  @override
  Future<void> setDisplayOrder(List<int> idsInOrder) async {
    await _db.writeTxn(() async {
      for (var i = 0; i < idsInOrder.length; i++) {
        final id = idsInOrder[i];
        final m = await _db.customReportWidgetModels.get(id);
        if (m == null) continue;
        m.sortOrder = i;
        await _db.customReportWidgetModels.put(m);
      }
    });
    BackupService.instance.triggerAutoSync();
  }
}
