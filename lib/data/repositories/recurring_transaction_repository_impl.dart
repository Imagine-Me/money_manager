import 'package:isar/isar.dart';
import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/data/datasources/local/isar_service.dart';
import 'package:money_manager/data/models/category_model.dart';
import 'package:money_manager/data/models/recurring_transaction_model.dart';
import 'package:money_manager/data/repositories/transaction_repository_impl.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/recurring_transaction_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';
import 'package:money_manager/domain/repositories/recurring_transaction_repository.dart';

class RecurringTransactionRepositoryImpl
    implements RecurringTransactionRepository {
  RecurringTransactionRepositoryImpl(this._service);

  final IsarService _service;

  Isar get _db => _service.db;

  // ─── Conversion ────────────────────────────────────────────────────────────

  RecurringTransactionEntity _toEntity(RecurringTransactionModel m) {
    CategoryEntity? cat;
    if (m.category.value != null) {
      final c = m.category.value!;
      cat = CategoryEntity(
        id: c.id,
        name: c.name,
        colorValue: c.colorValue,
        iconCodePoint: c.iconCodePoint,
        iconFontFamily: c.iconFontFamily,
        type: TransactionType.fromString(c.type),
        parentId: null,
      );
    }
    return RecurringTransactionEntity(
      id: m.id,
      title: m.title,
      amount: m.amount,
      type: TransactionType.fromString(m.type),
      note: m.note,
      frequency: RecurringFrequency.fromString(m.frequency),
      recurDay: m.recurDay,
      recurMonth: m.recurMonth,
      accountId: m.accountId,
      lastExecutedDate: m.lastExecutedDate,
      startDate: m.startDate,
      endDate: m.endDate,
      category: cat,
    );
  }

  // ─── Repository interface ──────────────────────────────────────────────────

  @override
  Future<List<RecurringTransactionEntity>> getAll() async {
    final models =
        await _db.recurringTransactionModels.where().findAll();
    for (final m in models) {
      await m.category.load();
    }
    return models.map(_toEntity).toList();
  }

  @override
  Future<int> save(
    RecurringTransactionEntity entity, [
    CategoryEntity? category,
  ]) async {
    return _db.writeTxn(() async {
      final model = RecurringTransactionModel()
        ..title = entity.title
        ..amount = entity.amount
        ..type = entity.type.name
        ..note = entity.note
        ..frequency = entity.frequency.name
        ..recurDay = entity.recurDay
        ..recurMonth = entity.recurMonth
        ..accountId = entity.accountId
        ..lastExecutedDate = entity.lastExecutedDate
        ..startDate = entity.startDate
        ..endDate = entity.endDate;

      if (entity.id > 0) model.id = entity.id;

      final savedId =
          await _db.recurringTransactionModels.put(model);

      if (category != null) {
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
              (await _db.categoryModels.get(category.id)) ??
                  (CategoryModel()
                    ..name = category.name
                    ..colorValue = category.colorValue
                    ..iconCodePoint = category.iconCodePoint
                    ..iconFontFamily = category.iconFontFamily
                    ..type = category.type.name);
          if (categoryModel.id == Isar.autoIncrement) {
            await _db.categoryModels.put(categoryModel);
          }
        }
        final saved =
            (await _db.recurringTransactionModels.get(savedId))!;
        saved.category.value = categoryModel;
        await saved.category.save();
      }

      return savedId;
    });
  }

  @override
  Future<void> delete(int id) async {
    await _db.writeTxn(() => _db.recurringTransactionModels.delete(id));
  }

  @override
  Future<void> markExecuted(int id, DateTime date) async {
    await _db.writeTxn(() async {
      final model = await _db.recurringTransactionModels.get(id);
      if (model != null) {
        model.lastExecutedDate = date;
        await _db.recurringTransactionModels.put(model);
      }
    });
  }

  @override
  Stream<List<RecurringTransactionEntity>> watchAll() {
    return _db.recurringTransactionModels
        .where()
        .watch(fireImmediately: true)
        .asyncMap((models) async {
      for (final m in models) {
        await m.category.load();
      }
      return models.map(_toEntity).toList();
    });
  }

  // ─── Due-transaction processing ────────────────────────────────────────────

  /// Checks every recurring template; if it's due today and hasn't been
  /// executed yet, creates a real transaction and marks the template.
  Future<void> processDueTransactions() async {
    final models =
        await _db.recurringTransactionModels.where().findAll();
    for (final model in models) {
      await model.category.load();
      final entity = _toEntity(model);
      if (!entity.isDueToday()) continue;

      final tx = TransactionEntity(
        id: 0,
        title: entity.title,
        amount: entity.amount,
        date: DateTime.now(),
        type: entity.type,
        note: entity.note,
        category: entity.category,
        accountId: entity.accountId,
      );

      final txRepo = TransactionRepositoryImpl(_service);
      await txRepo.save(tx, entity.category);

      final today = DateTime.now();
      await markExecuted(
        entity.id,
        DateTime(today.year, today.month, today.day),
      );
    }
  }
}
