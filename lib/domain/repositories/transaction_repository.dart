import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getAll();
  Future<TransactionEntity?> getById(int id);
  Future<List<TransactionEntity>> getByType(TransactionType type);
  Future<List<TransactionEntity>> getByDateRange(DateTime from, DateTime to);
  Future<int> save(TransactionEntity transaction, CategoryEntity category);
  Future<void> delete(int id);
  Stream<List<TransactionEntity>> watchAll();
  Future<List<TransactionEntity>> getRecent(int limit);
}
