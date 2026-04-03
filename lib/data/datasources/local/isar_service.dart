import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:money_manager/core/utils/category_seeder.dart';
import 'package:money_manager/data/models/account_model.dart';
import 'package:money_manager/data/models/category_model.dart';
import 'package:money_manager/data/models/transaction_model.dart';

class IsarService {
  IsarService._();

  static final IsarService instance = IsarService._();

  Isar? _isar;

  Isar get db {
    assert(_isar != null, 'IsarService not initialised — call open() first.');
    return _isar!;
  }

  Future<Isar> open() async {
    if (_isar != null && _isar!.isOpen) return _isar!;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [AccountModelSchema, CategoryModelSchema, TransactionModelSchema],
      directory: dir.path,
      name: 'vaultcash',
    );
    await CategorySeeder.seed(_isar!);
    return _isar!;
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
