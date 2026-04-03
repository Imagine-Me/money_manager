import 'package:isar/isar.dart';
import 'package:money_manager/data/datasources/local/isar_service.dart';
import 'package:money_manager/data/models/account_model.dart';
import 'package:money_manager/domain/entities/account_entity.dart';
import 'package:money_manager/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._service);

  final IsarService _service;

  Isar get _db => _service.db;

  @override
  Future<List<AccountEntity>> getAll() async {
    final models = await _db.accountModels.where().findAll();
    return models.map(_toEntity).toList();
  }

  @override
  Future<AccountEntity?> getById(int id) async {
    final model = await _db.accountModels.get(id);
    return model != null ? _toEntity(model) : null;
  }

  @override
  Future<int> save(AccountEntity account) async {
    return _db.writeTxn(() async {
      final model = AccountModel()
        ..name = account.name
        ..bankCode = account.bankCode
        ..balance = account.balance
        ..colorValue = account.colorValue
        ..isPrimary = account.isPrimary;
      if (account.id != 0) model.id = account.id;
      return _db.accountModels.put(model);
    });
  }

  @override
  Future<void> delete(int id) async {
    await _db.writeTxn(() => _db.accountModels.delete(id));
  }

  @override
  Future<void> setPrimary(int id) async {
    await _db.writeTxn(() async {
      final all = await _db.accountModels.where().findAll();
      for (final m in all) {
        final shouldBePrimary = m.id == id;
        if (m.isPrimary != shouldBePrimary) {
          m.isPrimary = shouldBePrimary;
          await _db.accountModels.put(m);
        }
      }
    });
  }

  @override
  Stream<List<AccountEntity>> watchAll() {
    return _db.accountModels
        .where()
        .watch(fireImmediately: true)
        .map((models) => models.map(_toEntity).toList());
  }

  AccountEntity _toEntity(AccountModel m) => AccountEntity(
        id: m.id,
        name: m.name,
        bankCode: m.bankCode,
        balance: m.balance,
        colorValue: m.colorValue,
        isPrimary: m.isPrimary,
      );
}
