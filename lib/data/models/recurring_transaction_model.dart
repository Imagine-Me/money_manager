import 'package:isar/isar.dart';
import 'package:money_manager/data/models/category_model.dart';

part 'recurring_transaction_model.g.dart';

@collection
class RecurringTransactionModel {
  Id id = Isar.autoIncrement;

  late String title;
  late double amount;
  late String type; // 'burn' or 'store'
  late String note;
  late String frequency; // 'weekly', 'monthly', 'yearly'

  /// For weekly: ISO weekday 1=Mon … 7=Sun.
  /// For monthly/yearly: day of month 1–31.
  late int recurDay;

  /// Only used for yearly: month of year 1–12.
  int recurMonth = 1;

  int? accountId;
  DateTime? lastExecutedDate;

  final category = IsarLink<CategoryModel>();
}
