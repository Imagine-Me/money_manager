import 'package:isar/isar.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/data/datasources/local/isar_service.dart';
import 'package:money_manager/data/models/category_model.dart';
import 'package:money_manager/data/models/transaction_model.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._service);

  final IsarService _service;

  Isar get _db => _service.db;

  @override
  Future<List<TransactionEntity>> getAll() async {
    final models = await _db.transactionModels
        .where()
        .sortByDateDesc()
        .findAll();
    await _loadCategories(models);
    return models.map(_toEntity).toList();
  }

  @override
  Future<TransactionEntity?> getById(int id) async {
    final model = await _db.transactionModels.get(id);
    if (model == null) return null;
    await model.category.load();
    return _toEntity(model);
  }

  @override
  Future<List<TransactionEntity>> getByType(TransactionType type) async {
    final models = await _db.transactionModels
        .where()
        .sortByDateDesc()
        .findAll();
    await _loadCategories(models);
    return models
        .where((m) => m.type == type.name)
        .map(_toEntity)
        .toList();
  }

  @override
  Future<List<TransactionEntity>> getByDateRange(
      DateTime from, DateTime to) async {
    final models = await _db.transactionModels
        .filter()
        .dateBetween(from, to)
        .sortByDateDesc()
        .findAll();
    await _loadCategories(models);
    return models.map(_toEntity).toList();
  }

  /// Saves a transaction. Creates the category if it doesn't already exist.
  @override
  Future<int> save(
      TransactionEntity transaction, CategoryEntity category) async {
    return _db.writeTxn(() async {
      // Upsert category — create if id is 0 (new), otherwise reuse existing.
      CategoryModel categoryModel;
      if (category.id <= 0) {
        categoryModel = CategoryModel()
          ..name = category.name
          ..colorValue = category.colorValue
          ..iconCodePoint = category.iconCodePoint
          ..iconFontFamily = category.iconFontFamily
          ..type = category.type.name;
        await _db.categoryModels.put(categoryModel);
      } else {
        categoryModel =
            (await _db.categoryModels.get(category.id)) ?? CategoryModel()
              ..name = category.name
              ..colorValue = category.colorValue
              ..iconCodePoint = category.iconCodePoint
              ..iconFontFamily = category.iconFontFamily
              ..type = category.type.name;
        if (categoryModel.id == Isar.autoIncrement) {
          await _db.categoryModels.put(categoryModel);
        }
      }

      final model = TransactionModel()
        ..title = transaction.title
        ..amount = transaction.amount
        ..date = transaction.date
        ..type = transaction.type.name
        ..note = transaction.note
        ..accountId = transaction.accountId;

      if (transaction.id > 0) model.id = transaction.id;

      final txId = await _db.transactionModels.put(model);

      // Load the newly saved model to attach link.
      final saved = (await _db.transactionModels.get(txId))!;
      saved.category.value = categoryModel;
      await saved.category.save();

      return txId;
    });
  }

  @override
  Future<void> delete(int id) async {
    await _db.writeTxn(() => _db.transactionModels.delete(id));
  }

  @override
  Stream<List<TransactionEntity>> watchAll() {
    return _db.transactionModels
        .where()
        .watch(fireImmediately: true)
        .asyncMap((models) async {
      await _loadCategories(models);
      models.sort((a, b) => b.date.compareTo(a.date));
      return models.map(_toEntity).toList();
    });
  }

  @override
  Future<List<TransactionEntity>> getRecent(int limit) async {
    final models = await _db.transactionModels
        .where()
        .sortByDateDesc()
        .limit(limit)
        .findAll();
    await _loadCategories(models);
    return models.map(_toEntity).toList();
  }

  Future<void> _loadCategories(List<TransactionModel> models) async {
    await Future.wait(models.map((m) => m.category.load()));
  }

  TransactionEntity _toEntity(TransactionModel m) {
    final cat = m.category.value;
    return TransactionEntity(
      id: m.id,
      title: m.title,
      amount: m.amount,
      date: m.date,
      type: TransactionType.fromString(m.type),
      note: m.note,
      accountId: m.accountId,
      category: cat != null
          ? CategoryEntity(
              id: cat.id,
              name: cat.name,
              colorValue: cat.colorValue,
              iconCodePoint: cat.iconCodePoint,
              iconFontFamily: cat.iconFontFamily,
              type: TransactionType.fromString(cat.type),
              parentId: cat.parentId,
            )
          : null,
    );
  }
}
