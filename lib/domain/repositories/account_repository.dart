import '../entities/account_entity.dart';

abstract class AccountRepository {
  Future<List<AccountEntity>> getAll();
  Future<AccountEntity?> getById(int id);
  Future<int> save(AccountEntity account);
  Future<void> delete(int id);
  Future<void> setPrimary(int id);
  Stream<List<AccountEntity>> watchAll();
}
