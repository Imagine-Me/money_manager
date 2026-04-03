import 'package:money_manager/domain/entities/category_entity.dart';
import 'package:money_manager/domain/entities/recurring_transaction_entity.dart';

abstract class RecurringTransactionRepository {
  Future<List<RecurringTransactionEntity>> getAll();

  Future<int> save(
    RecurringTransactionEntity entity, [
    CategoryEntity? category,
  ]);

  Future<void> delete(int id);

  Future<void> markExecuted(int id, DateTime date);

  Future<void> processDueTransactions();

  Stream<List<RecurringTransactionEntity>> watchAll();
}
