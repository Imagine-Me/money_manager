import 'package:money_manager/core/constants/app_constants.dart';
import 'package:money_manager/domain/entities/category_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getAll();
  Future<CategoryEntity?> getById(int id);
  Future<List<CategoryEntity>> searchByName(String query);
  Future<int> save(CategoryEntity category);
  Future<void> delete(int id);
  Stream<List<CategoryEntity>> watchAll();
  Future<List<CategoryEntity>> getByType(TransactionType type);
}
