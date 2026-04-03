import 'package:isar/isar.dart';
import 'package:money_manager/data/models/category_model.dart';

part 'transaction_model.g.dart';

@collection
class TransactionModel {
  Id id = Isar.autoIncrement;

  late String title;
  late double amount;
  late DateTime date;
  late String type; // 'burn' or 'store'
  late String note;
  int? accountId;

  final category = IsarLink<CategoryModel>();
}
