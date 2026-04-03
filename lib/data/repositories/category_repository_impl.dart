import 'package:isar/isar.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/data/datasources/local/isar_service.dart';
import 'package:money_manager/data/models/category_model.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._service);

  final IsarService _service;

  Isar get _db => _service.db;

  @override
  Future<List<CategoryEntity>> getAll() async {
    final models = await _db.categoryModels.where().findAll();
    return models.map(_toEntity).toList();
  }

  @override
  Future<CategoryEntity?> getById(int id) async {
    final model = await _db.categoryModels.get(id);
    return model != null ? _toEntity(model) : null;
  }

  @override
  Future<List<CategoryEntity>> searchByName(String query) async {
    if (query.isEmpty) return getAll();
    final all = await _db.categoryModels.where().findAll();
    final lower = query.toLowerCase();
    return all
        .where((m) => m.name.toLowerCase().contains(lower))
        .map(_toEntity)
        .toList();
  }

  @override
  Future<int> save(CategoryEntity category) async {
    final model = _toModel(category);
    return _db.writeTxn(() => _db.categoryModels.put(model));
  }

  @override
  Future<void> delete(int id) async {
    await _db.writeTxn(() => _db.categoryModels.delete(id));
  }

  @override
  Stream<List<CategoryEntity>> watchAll() {
    return _db.categoryModels
        .where()
        .watch(fireImmediately: true)
        .map((models) => models.map(_toEntity).toList());
  }

  @override
  Future<List<CategoryEntity>> getByType(TransactionType type) async {
    final all = await _db.categoryModels.where().findAll();
    return all
        .where((m) => m.type == type.name)
        .map(_toEntity)
        .toList();
  }

  CategoryEntity _toEntity(CategoryModel m) => CategoryEntity(
        id: m.id,
        name: m.name,
        colorValue: m.colorValue,
        iconCodePoint: m.iconCodePoint,
        iconFontFamily: m.iconFontFamily,
        type: TransactionType.fromString(m.type),
        parentId: m.parentId,
      );

  CategoryModel _toModel(CategoryEntity e) {
    final m = CategoryModel()
      ..name = e.name
      ..colorValue = e.colorValue
      ..iconCodePoint = e.iconCodePoint
      ..iconFontFamily = e.iconFontFamily
      ..type = e.type.name
      ..parentId = e.parentId;
    if (e.id > 0) m.id = e.id;
    return m;
  }

  @override
  Future<List<CategoryEntity>> getTopLevel() async {
    final all = await _db.categoryModels.where().findAll();
    return all.where((m) => m.parentId == null).map(_toEntity).toList();
  }

  @override
  Future<List<CategoryEntity>> getSubcategories(int parentId) async {
    final all = await _db.categoryModels.where().findAll();
    return all.where((m) => m.parentId == parentId).map(_toEntity).toList();
  }
}
